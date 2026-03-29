#ifndef HOOK_H
#define HOOK_H

#include "config.h"

/* 在后台线程启动鼠标钩子，立即返回 */
int hook_start_async(Config *cfg);

/* 卸载钩子并停止后台线程 */
void hook_stop(void);

#endif /* HOOK_H */
