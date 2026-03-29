#ifndef CONFIG_H
#define CONFIG_H

#include <windows.h>

#define MAX_MAPPINGS  16
#define MAX_KEY_COMBO 8

/* ── 动作类型 ── */
typedef enum {
    ACTION_CLICK,
    ACTION_HOLD
} ActionType;

/* ── 单个键映射 ── */
typedef struct {
    WORD vkCode;
    int  isModifier;
    int  isExtended;   /* 需要 KEYEVENTF_EXTENDEDKEY */
} KeyMapping;

/* ── 单条按钮映射 ── */
typedef struct {
    int        button;          /* 鼠标按键编号: 2=中键, 3=侧键后, 4=侧键前 */
    char       key[64];         /* 原始键名字符串 */
    ActionType action;
    KeyMapping keys[MAX_KEY_COMBO];
    int        keyCount;
} Mapping;

/* ── 全局配置 ── */
typedef struct {
    Mapping mappings[MAX_MAPPINGS];
    int     count;
} Config;

/* ── API ── */
Config      load_config(void);
int         resolve_keys(const char *keyString, KeyMapping *out, int maxKeys);
const char *mouse_button_name(int button);

#endif /* CONFIG_H */
