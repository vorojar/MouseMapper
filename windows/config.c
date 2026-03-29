#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ================================================================
 *  键名 → VK 码映射表
 * ================================================================ */

typedef struct {
    const char *name;
    WORD        vkCode;
    int         isModifier;
    int         isExtended;
} KeyTableEntry;

static const KeyTableEntry keyTable[] = {
    /* ── 修饰键 ── */
    {"shift",          VK_LSHIFT,   1, 0},
    {"left_shift",     VK_LSHIFT,   1, 0},
    {"right_shift",    VK_RSHIFT,   1, 0},
    {"control",        VK_LCONTROL, 1, 0},
    {"ctrl",           VK_LCONTROL, 1, 0},
    {"left_control",   VK_LCONTROL, 1, 0},
    {"right_control",  VK_RCONTROL, 1, 1},
    {"alt",            VK_LMENU,    1, 0},
    {"left_alt",       VK_LMENU,    1, 0},
    {"right_alt",      VK_RMENU,    1, 1},
    {"option",         VK_LMENU,    1, 0},   /* macOS 兼容 */
    {"left_option",    VK_LMENU,    1, 0},
    {"right_option",   VK_RMENU,    1, 1},
    {"command",        VK_LWIN,     1, 1},   /* macOS command → Win 键 */
    {"left_command",   VK_LWIN,     1, 1},
    {"right_command",  VK_RWIN,     1, 1},
    {"win",            VK_LWIN,     1, 1},
    {"left_win",       VK_LWIN,     1, 1},
    {"right_win",      VK_RWIN,     1, 1},
    {"caps_lock",      VK_CAPITAL,  1, 0},

    /* ── 功能键 ── */
    {"f1",  VK_F1,  0, 0}, {"f2",  VK_F2,  0, 0}, {"f3",  VK_F3,  0, 0},
    {"f4",  VK_F4,  0, 0}, {"f5",  VK_F5,  0, 0}, {"f6",  VK_F6,  0, 0},
    {"f7",  VK_F7,  0, 0}, {"f8",  VK_F8,  0, 0}, {"f9",  VK_F9,  0, 0},
    {"f10", VK_F10, 0, 0}, {"f11", VK_F11, 0, 0}, {"f12", VK_F12, 0, 0},

    /* ── 常用键 ── */
    {"escape",         VK_ESCAPE,   0, 0},
    {"esc",            VK_ESCAPE,   0, 0},
    {"return",         VK_RETURN,   0, 0},
    {"enter",          VK_RETURN,   0, 0},
    {"tab",            VK_TAB,      0, 0},
    {"space",          VK_SPACE,    0, 0},
    {"backspace",      VK_BACK,     0, 0},
    {"delete",         VK_BACK,     0, 0},   /* macOS delete = Backspace */
    {"forward_delete", VK_DELETE,   0, 1},
    {"insert",         VK_INSERT,   0, 1},
    {"print_screen",   VK_SNAPSHOT, 0, 0},
    {"scroll_lock",    VK_SCROLL,   0, 0},
    {"pause",          VK_PAUSE,    0, 0},

    /* ── 方向键 ── */
    {"up",        VK_UP,    0, 1},
    {"down",      VK_DOWN,  0, 1},
    {"left",      VK_LEFT,  0, 1},
    {"right",     VK_RIGHT, 0, 1},
    {"home",      VK_HOME,  0, 1},
    {"end",       VK_END,   0, 1},
    {"page_up",   VK_PRIOR, 0, 1},
    {"page_down", VK_NEXT,  0, 1},

    /* ── 字母键 a-z (VK 码 = 大写 ASCII) ── */
    {"a", 'A', 0, 0}, {"b", 'B', 0, 0}, {"c", 'C', 0, 0}, {"d", 'D', 0, 0},
    {"e", 'E', 0, 0}, {"f", 'F', 0, 0}, {"g", 'G', 0, 0}, {"h", 'H', 0, 0},
    {"i", 'I', 0, 0}, {"j", 'J', 0, 0}, {"k", 'K', 0, 0}, {"l", 'L', 0, 0},
    {"m", 'M', 0, 0}, {"n", 'N', 0, 0}, {"o", 'O', 0, 0}, {"p", 'P', 0, 0},
    {"q", 'Q', 0, 0}, {"r", 'R', 0, 0}, {"s", 'S', 0, 0}, {"t", 'T', 0, 0},
    {"u", 'U', 0, 0}, {"v", 'V', 0, 0}, {"w", 'W', 0, 0}, {"x", 'X', 0, 0},
    {"y", 'Y', 0, 0}, {"z", 'Z', 0, 0},

    /* ── 数字键 0-9 ── */
    {"0", '0', 0, 0}, {"1", '1', 0, 0}, {"2", '2', 0, 0}, {"3", '3', 0, 0},
    {"4", '4', 0, 0}, {"5", '5', 0, 0}, {"6", '6', 0, 0}, {"7", '7', 0, 0},
    {"8", '8', 0, 0}, {"9", '9', 0, 0},

    /* ── 符号键 ── */
    {"-",  VK_OEM_MINUS,  0, 0},
    {"=",  VK_OEM_PLUS,   0, 0},
    {"[",  VK_OEM_4,      0, 0},
    {"]",  VK_OEM_6,      0, 0},
    {"\\", VK_OEM_5,      0, 0},
    {";",  VK_OEM_1,      0, 0},
    {"'",  VK_OEM_7,      0, 0},
    {",",  VK_OEM_COMMA,  0, 0},
    {".",  VK_OEM_PERIOD, 0, 0},
    {"/",  VK_OEM_2,      0, 0},
    {"`",  VK_OEM_3,      0, 0},

    {NULL, 0, 0, 0}  /* 哨兵 */
};

/* ── 查找单个键名 ── */
static const KeyTableEntry *find_key(const char *name)
{
    for (int i = 0; keyTable[i].name != NULL; i++) {
        if (_stricmp(keyTable[i].name, name) == 0)
            return &keyTable[i];
    }
    return NULL;
}

/* ── 解析组合键字符串，如 "shift+command+a" ── */
int resolve_keys(const char *keyString, KeyMapping *out, int maxKeys)
{
    char buf[256];
    strncpy(buf, keyString, sizeof(buf) - 1);
    buf[sizeof(buf) - 1] = '\0';

    int count = 0;
    char *token = strtok(buf, "+");
    while (token && count < maxKeys) {
        /* 去首尾空白 */
        while (*token == ' ') token++;
        char *end = token + strlen(token) - 1;
        while (end > token && *end == ' ') *end-- = '\0';

        const KeyTableEntry *entry = find_key(token);
        if (!entry) {
            fprintf(stderr, "  [!] 未知键名: %s\n", token);
            return 0;
        }
        out[count].vkCode     = entry->vkCode;
        out[count].isModifier  = entry->isModifier;
        out[count].isExtended  = entry->isExtended;
        count++;
        token = strtok(NULL, "+");
    }
    return count;
}

/* ================================================================
 *  简易 JSON 解析（仅处理 config.json 格式）
 * ================================================================ */

/* 跳过空白 */
static const char *skip_ws(const char *p)
{
    while (*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
    return p;
}

/* 读取带引号的字符串，返回结束位置（引号之后） */
static const char *read_string(const char *p, char *out, int maxLen)
{
    if (*p != '"') return NULL;
    p++; /* skip opening quote */
    int i = 0;
    while (*p && *p != '"' && i < maxLen - 1) {
        if (*p == '\\' && *(p + 1)) { p++; } /* 简单转义 */
        out[i++] = *p++;
    }
    out[i] = '\0';
    if (*p == '"') p++; /* skip closing quote */
    return p;
}

/* 读取整数 */
static const char *read_int(const char *p, int *out)
{
    char buf[16];
    int i = 0;
    if (*p == '-') buf[i++] = *p++;
    while (*p >= '0' && *p <= '9' && i < 15) buf[i++] = *p++;
    buf[i] = '\0';
    *out = atoi(buf);
    return p;
}

/* 解析单个 mapping 对象 */
static const char *parse_mapping(const char *p, Mapping *m)
{
    m->button   = -1;
    m->key[0]   = '\0';
    m->action   = ACTION_CLICK;
    m->keyCount = 0;

    p = skip_ws(p);
    if (*p != '{') return NULL;
    p++;

    while (*p && *p != '}') {
        p = skip_ws(p);
        if (!*p || *p == '}') break;
        if (*p == ',') { p++; continue; }
        if (*p != '"') { p++; continue; }

        char fieldName[32];
        p = read_string(p, fieldName, sizeof(fieldName));
        if (!p) return NULL;

        p = skip_ws(p);
        if (*p == ':') p++;
        p = skip_ws(p);

        if (strcmp(fieldName, "button") == 0) {
            p = read_int(p, &m->button);
        } else if (strcmp(fieldName, "key") == 0) {
            p = read_string(p, m->key, sizeof(m->key));
            if (!p) return NULL;
        } else if (strcmp(fieldName, "action") == 0) {
            char action[16];
            p = read_string(p, action, sizeof(action));
            if (!p) return NULL;
            m->action = (_stricmp(action, "hold") == 0) ? ACTION_HOLD : ACTION_CLICK;
        } else {
            /* 跳过未知字段值 */
            if (*p == '"') {
                char tmp[256];
                p = read_string(p, tmp, sizeof(tmp));
            } else {
                while (*p && *p != ',' && *p != '}') p++;
            }
        }
    }
    if (*p == '}') p++;

    /* 解析键映射 */
    if (m->key[0] && m->button >= 0) {
        m->keyCount = resolve_keys(m->key, m->keys, MAX_KEY_COMBO);
    }
    return p;
}

/* 解析整个 config JSON */
static int parse_config_json(const char *json, Config *cfg)
{
    cfg->count = 0;

    /* 找到 "mappings" 数组 */
    const char *p = strstr(json, "\"mappings\"");
    if (!p) return 0;
    p += strlen("\"mappings\"");
    p = skip_ws(p);
    if (*p == ':') p++;
    p = skip_ws(p);
    if (*p != '[') return 0;
    p++;

    while (*p && *p != ']' && cfg->count < MAX_MAPPINGS) {
        p = skip_ws(p);
        if (!*p || *p == ']') break;
        if (*p == ',') { p++; continue; }
        if (*p == '{') {
            p = parse_mapping(p, &cfg->mappings[cfg->count]);
            if (!p) return 0;
            if (cfg->mappings[cfg->count].keyCount > 0)
                cfg->count++;
        } else {
            p++;
        }
    }
    return cfg->count;
}

/* ================================================================
 *  配置文件加载（exe 同目录）
 * ================================================================ */

static char *read_file(const char *path)
{
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (len <= 0 || len > 1024 * 1024) { fclose(f); return NULL; }
    char *buf = (char *)malloc(len + 1);
    if (!buf) { fclose(f); return NULL; }
    fread(buf, 1, len, f);
    buf[len] = '\0';
    fclose(f);
    return buf;
}

static int try_load(const char *path, Config *cfg)
{
    char *json = read_file(path);
    if (!json) return 0;
    int ok = parse_config_json(json, cfg);
    free(json);
    if (ok > 0) {
        printf("[OK] 已加载配置: %s\n", path);
        return 1;
    }
    fprintf(stderr, "[!] 配置文件解析失败: %s\n", path);
    return 0;
}

/* 默认配置 JSON 模板 */
static const char *DEFAULT_CONFIG =
    "{\r\n"
    "  \"mappings\": [\r\n"
    "    {\r\n"
    "      \"button\": 3,\r\n"
    "      \"key\": \"return\",\r\n"
    "      \"action\": \"click\"\r\n"
    "    },\r\n"
    "    {\r\n"
    "      \"button\": 4,\r\n"
    "      \"key\": \"alt\",\r\n"
    "      \"action\": \"hold\"\r\n"
    "    }\r\n"
    "  ]\r\n"
    "}\r\n";

/* 获取 exe 同目录的 config.json 路径 */
static void get_config_path(char *out, int maxLen)
{
    GetModuleFileNameA(NULL, out, maxLen);
    char *last = strrchr(out, '\\');
    if (last) *(last + 1) = '\0';
    else out[0] = '\0';
    strncat(out, "config.json", maxLen - (int)strlen(out) - 1);
}

Config load_config(void)
{
    Config cfg;
    memset(&cfg, 0, sizeof(cfg));

    char path[MAX_PATH];
    get_config_path(path, MAX_PATH);

    if (try_load(path, &cfg))
        return cfg;

    /* 不存在则自动生成默认配置文件 */
    printf("[!] 未找到 config.json，自动生成默认配置...\n");
    FILE *f = fopen(path, "wb");
    if (f) {
        fwrite(DEFAULT_CONFIG, 1, strlen(DEFAULT_CONFIG), f);
        fclose(f);
        printf("[OK] 已生成: %s\n", path);
        if (try_load(path, &cfg))
            return cfg;
    } else {
        fprintf(stderr, "[!] 无法写入: %s\n", path);
    }

    return cfg;
}

/* ── 按键名称 ── */
const char *mouse_button_name(int button)
{
    switch (button) {
        case 2:  return "Middle";
        case 3:  return "Back(X1)";
        case 4:  return "Forward(X2)";
        default: {
            static char buf[16];
            snprintf(buf, sizeof(buf), "Button%d", button);
            return buf;
        }
    }
}
