#include <stdio.h>
#include <string.h>
#include "config.h"
#include "hook.h"
#include <shellapi.h>

/* ================================================================
 *  常量
 * ================================================================ */

#define WM_TRAYICON    (WM_USER + 1)
#define ID_TRAY        1
#define IDM_AUTOSTART  2001
#define IDM_UNINSTALL  2002
#define IDM_EXIT       2003

static const wchar_t *WNDCLASS_NAME = L"MouseMapperTray";
static const char    *REG_RUN_KEY   = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
static const char    *REG_VALUE     = "MouseMapper";

static HWND            g_hwnd = NULL;
static NOTIFYICONDATAW g_nid;
static Config          g_cfg;

/* ================================================================
 *  UTF-8 → wchar_t 转换
 * ================================================================ */

static void utf8_to_wchar(const char *utf8, wchar_t *out, int maxChars)
{
    MultiByteToWideChar(CP_UTF8, 0, utf8, -1, out, maxChars);
}

/* ================================================================
 *  自启管理
 * ================================================================ */

static int is_autostart(void)
{
    HKEY hKey;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, REG_RUN_KEY, 0, KEY_READ, &hKey) != ERROR_SUCCESS)
        return 0;
    LONG ret = RegQueryValueExA(hKey, REG_VALUE, NULL, NULL, NULL, NULL);
    RegCloseKey(hKey);
    return (ret == ERROR_SUCCESS);
}

static void set_autostart(int enable)
{
    HKEY hKey;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, REG_RUN_KEY, 0, KEY_SET_VALUE, &hKey) != ERROR_SUCCESS)
        return;

    if (enable) {
        char exePath[MAX_PATH];
        GetModuleFileNameA(NULL, exePath, MAX_PATH);
        char value[MAX_PATH + 4];
        snprintf(value, sizeof(value), "\"%s\"", exePath);
        RegSetValueExA(hKey, REG_VALUE, 0, REG_SZ,
                       (const BYTE *)value, (DWORD)(strlen(value) + 1));
    } else {
        RegDeleteValueA(hKey, REG_VALUE);
    }
    RegCloseKey(hKey);
}

static void delete_config(void)
{
    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    char *last = strrchr(path, '\\');
    if (last) *(last + 1) = '\0';
    strncat(path, "config.json", MAX_PATH - (int)strlen(path) - 1);
    DeleteFileA(path);
}

/* ================================================================
 *  托盘图标
 * ================================================================ */

static void tray_add(HWND hwnd)
{

    ZeroMemory(&g_nid, sizeof(g_nid));
    g_nid.cbSize           = sizeof(NOTIFYICONDATAW);
    g_nid.hWnd             = hwnd;
    g_nid.uID              = ID_TRAY;
    g_nid.uFlags           = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_INFO;
    g_nid.uCallbackMessage = WM_TRAYICON;
    /* 从 exe 资源加载图标（ID=1，和 app.rc 对应） */
    g_nid.hIcon            = LoadIcon(GetModuleHandle(NULL), MAKEINTRESOURCE(1));
    g_nid.dwInfoFlags      = NIIF_INFO;
    wcscpy(g_nid.szTip, L"MouseMapper");
    wcscpy(g_nid.szInfoTitle, L"MouseMapper");
    wcscpy(g_nid.szInfo, L"鼠标映射已启动");
    Shell_NotifyIconW(NIM_ADD, &g_nid);
}

static void tray_remove(void)
{
    Shell_NotifyIconW(NIM_DELETE, &g_nid);
}

static void tray_show_menu(HWND hwnd)
{
    HMENU hMenu = CreatePopupMenu();
    int autoOn = is_autostart();

    /* 映射信息（灰色，不可点击） */
    for (int i = 0; i < g_cfg.count; i++) {
        Mapping *m = &g_cfg.mappings[i];
        char buf[128];
        const char *act = (m->action == ACTION_HOLD) ? "按住" : "点击";
        snprintf(buf, sizeof(buf), "%s -> %s (%s)",
                 mouse_button_name(m->button), m->key, act);
        wchar_t wbuf[128];
        utf8_to_wchar(buf, wbuf, 128);
        AppendMenuW(hMenu, MF_STRING | MF_GRAYED, 0, wbuf);
    }

    AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);

    AppendMenuW(hMenu, MF_STRING | (autoOn ? MF_CHECKED : 0),
                IDM_AUTOSTART, L"开机自启");

    AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hMenu, MF_STRING, IDM_EXIT, L"退出");

    POINT pt;
    GetCursorPos(&pt);
    SetForegroundWindow(hwnd);
    TrackPopupMenu(hMenu, TPM_RIGHTALIGN | TPM_BOTTOMALIGN,
                   pt.x, pt.y, 0, hwnd, NULL);
    DestroyMenu(hMenu);
}

/* ================================================================
 *  窗口过程
 * ================================================================ */

static LRESULT CALLBACK wnd_proc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
    case WM_TRAYICON:
        if (lParam == WM_RBUTTONUP || lParam == WM_LBUTTONUP) {
            tray_show_menu(hwnd);
        }
        return 0;

    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_AUTOSTART:
            set_autostart(!is_autostart());
            break;
        case IDM_UNINSTALL:
            set_autostart(0);
            delete_config();
            hook_stop();
            tray_remove();
            MessageBoxW(NULL,
                        L"已卸载 MouseMapper\n\n"
                        L"- 已移除开机自启\n"
                        L"- 已删除 config.json\n"
                        L"- exe 文件请手动删除",
                        L"MouseMapper", MB_OK | MB_ICONINFORMATION);
            PostQuitMessage(0);
            break;
        case IDM_EXIT:
            hook_stop();
            tray_remove();
            PostQuitMessage(0);
            break;
        }
        return 0;

    case WM_DESTROY:
        hook_stop();
        tray_remove();
        PostQuitMessage(0);
        return 0;
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

/* ================================================================
 *  主入口（Windows 子系统，无控制台）
 * ================================================================ */

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrev, LPSTR lpCmdLine, int nCmdShow)
{
    (void)hPrev; (void)nCmdShow;

    /* 防止多开 */
    HANDLE hMutex = CreateMutexA(NULL, TRUE, "MouseMapperSingleInstance");
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        MessageBoxW(NULL, L"MouseMapper 已在运行中", L"MouseMapper", MB_OK | MB_ICONINFORMATION);
        return 0;
    }

    /* --uninstall 支持 */
    if (lpCmdLine && strstr(lpCmdLine, "--uninstall")) {
        set_autostart(0);
        return 0;
    }

    /* 加载配置 */
    g_cfg = load_config();
    if (g_cfg.count == 0) {
        MessageBoxW(NULL, L"没有配置任何映射", L"MouseMapper", MB_OK | MB_ICONWARNING);
        return 0;
    }

    /* 自动设置开机自启 */
    set_autostart(1);

    /* 启动鼠标钩子 */
    if (!hook_start_async(&g_cfg)) {
        MessageBoxW(NULL, L"无法启动鼠标钩子", L"MouseMapper", MB_OK | MB_ICONERROR);
        return 1;
    }

    /* 创建隐藏窗口（接收托盘消息） */
    WNDCLASSW wc;
    ZeroMemory(&wc, sizeof(wc));
    wc.lpfnWndProc   = wnd_proc;
    wc.hInstance      = hInstance;
    wc.lpszClassName  = WNDCLASS_NAME;
    RegisterClassW(&wc);

    g_hwnd = CreateWindowExW(0, WNDCLASS_NAME, L"MouseMapper", 0,
                             0, 0, 0, 0, HWND_MESSAGE, NULL, hInstance, NULL);

    /* 添加托盘图标 */
    tray_add(g_hwnd);

    /* 消息循环 */
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    ReleaseMutex(hMutex);
    CloseHandle(hMutex);
    return 0;
}
