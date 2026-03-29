#include "hook.h"
#include <stdio.h>
#include <process.h>  /* _beginthreadex */

/* ================================================================
 *  全局状态
 * ================================================================ */

static HHOOK    g_mouseHook = NULL;
static Config  *g_config    = NULL;

/* hold 模式：记录每个按钮当前按住的键 */
static KeyMapping g_heldKeys[16][MAX_KEY_COMBO];
static int        g_heldCount[16] = {0};

/* ================================================================
 *  工作线程：异步执行 SendInput
 *
 *  钩子回调只做一件事：把 (button, isDown) 投递到工作线程，
 *  立即返回，避免被 move 事件排队或 SendInput 延迟拖慢。
 * ================================================================ */

/* 投递给工作线程的命令 */
typedef struct {
    int button;
    int isDown;
} KeyCommand;

#define CMD_QUEUE_SIZE 64

static KeyCommand g_cmdQueue[CMD_QUEUE_SIZE];
static volatile LONG g_cmdHead = 0;  /* 写位置（回调线程写） */
static volatile LONG g_cmdTail = 0;  /* 读位置（工作线程读） */
static HANDLE g_cmdEvent = NULL;     /* 通知工作线程有新命令 */
static HANDLE g_workerThread = NULL;
static volatile int g_workerRunning = 1;

static void send_key_event(const KeyMapping *km, int keyDown)
{
    INPUT input;
    ZeroMemory(&input, sizeof(input));
    input.type       = INPUT_KEYBOARD;
    input.ki.wVk     = km->vkCode;
    input.ki.wScan   = (WORD)MapVirtualKeyA(km->vkCode, MAPVK_VK_TO_VSC);
    input.ki.dwFlags = keyDown ? 0 : KEYEVENTF_KEYUP;

    if (km->isExtended)
        input.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;

    SendInput(1, &input, sizeof(INPUT));
}

/* 处理一条命令（在工作线程执行） */
static void process_command(int button, int isDown)
{
    Mapping *mapping = NULL;
    for (int i = 0; i < g_config->count; i++) {
        if (g_config->mappings[i].button == button) {
            mapping = &g_config->mappings[i];
            break;
        }
    }
    if (!mapping) return;

    switch (mapping->action) {
    case ACTION_HOLD:
        if (isDown) {
            for (int i = 0; i < mapping->keyCount; i++) {
                send_key_event(&mapping->keys[i], 1);
                g_heldKeys[button][i] = mapping->keys[i];
            }
            g_heldCount[button] = mapping->keyCount;
        } else {
            for (int i = g_heldCount[button] - 1; i >= 0; i--)
                send_key_event(&g_heldKeys[button][i], 0);
            g_heldCount[button] = 0;
        }
        break;

    case ACTION_CLICK:
        if (isDown) {
            for (int i = 0; i < mapping->keyCount; i++)
                send_key_event(&mapping->keys[i], 1);
            for (int i = mapping->keyCount - 1; i >= 0; i--)
                send_key_event(&mapping->keys[i], 0);
        }
        break;
    }
}

/* 工作线程入口 */
static unsigned __stdcall worker_thread(void *arg)
{
    (void)arg;
    while (g_workerRunning) {
        WaitForSingleObject(g_cmdEvent, INFINITE);

        /* 批量处理队列中所有命令 */
        while (g_cmdTail != g_cmdHead) {
            LONG idx = g_cmdTail % CMD_QUEUE_SIZE;
            KeyCommand cmd = g_cmdQueue[idx];
            InterlockedIncrement(&g_cmdTail);
            process_command(cmd.button, cmd.isDown);
        }
    }
    return 0;
}

/* 回调中调用：投递命令到工作线程 */
static void post_command(int button, int isDown)
{
    LONG idx = g_cmdHead % CMD_QUEUE_SIZE;
    g_cmdQueue[idx].button = button;
    g_cmdQueue[idx].isDown = isDown;
    InterlockedIncrement(&g_cmdHead);
    SetEvent(g_cmdEvent);
}

/* ================================================================
 *  鼠标 Hook 回调（极快返回）
 * ================================================================ */

static LRESULT CALLBACK mouse_proc(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode < 0 || !g_config)
        return CallNextHookEx(g_mouseHook, nCode, wParam, lParam);

    MSLLHOOKSTRUCT *ms = (MSLLHOOKSTRUCT *)lParam;
    int button = -1;
    int isDown = 0;

    switch (wParam) {
    case WM_MBUTTONDOWN:
        button = 2; isDown = 1;
        break;
    case WM_MBUTTONUP:
        button = 2; isDown = 0;
        break;
    case WM_XBUTTONDOWN:
        button = (HIWORD(ms->mouseData) == XBUTTON1) ? 3 : 4;
        isDown = 1;
        break;
    case WM_XBUTTONUP:
        button = (HIWORD(ms->mouseData) == XBUTTON1) ? 3 : 4;
        isDown = 0;
        break;
    default:
        return CallNextHookEx(g_mouseHook, nCode, wParam, lParam);
    }

    /* 检查是否有对应映射 */
    int found = 0;
    for (int i = 0; i < g_config->count; i++) {
        if (g_config->mappings[i].button == button) {
            found = 1;
            break;
        }
    }

    if (!found)
        return CallNextHookEx(g_mouseHook, nCode, wParam, lParam);

    /* 投递到工作线程，立即返回 */
    post_command(button, isDown);
    return 1;  /* 吞掉原始鼠标事件 */
}

/* ================================================================
 *  公开 API
 * ================================================================ */

/* 钩子线程：安装钩子 + 消息循环 */
static DWORD g_hookThreadId = 0;

static unsigned __stdcall hook_thread(void *arg)
{
    Config *cfg = (Config *)arg;
    g_config = cfg;

    g_mouseHook = SetWindowsHookExA(WH_MOUSE_LL, mouse_proc, NULL, 0);
    if (!g_mouseHook) {
        fprintf(stderr, "[!] 无法安装鼠标钩子 (错误码 %lu)\n", GetLastError());
        return 1;
    }

    /* 消息循环：WH_MOUSE_LL 必须有消息循环才能工作 */
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    UnhookWindowsHookEx(g_mouseHook);
    g_mouseHook = NULL;
    return 0;
}

int hook_start_async(Config *cfg)
{
    /* 启动 SendInput 工作线程 */
    g_cmdEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
    g_workerRunning = 1;
    g_workerThread = (HANDLE)_beginthreadex(NULL, 0, worker_thread, NULL, 0, NULL);

    /* 启动钩子线程 */
    HANDLE ht = (HANDLE)_beginthreadex(NULL, 0, hook_thread, cfg, 0, (unsigned *)&g_hookThreadId);
    if (!ht) return 0;
    CloseHandle(ht);

    /* 等一下确认钩子装上了 */
    Sleep(100);
    return (g_mouseHook != NULL);
}

void hook_stop(void)
{
    /* 让钩子线程的消息循环退出 */
    if (g_hookThreadId)
        PostThreadMessage(g_hookThreadId, WM_QUIT, 0, 0);

    /* 停止工作线程 */
    g_workerRunning = 0;
    if (g_cmdEvent) SetEvent(g_cmdEvent);
    if (g_workerThread) {
        WaitForSingleObject(g_workerThread, 1000);
        CloseHandle(g_workerThread);
        g_workerThread = NULL;
    }
    if (g_cmdEvent) {
        CloseHandle(g_cmdEvent);
        g_cmdEvent = NULL;
    }
}
