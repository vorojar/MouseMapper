# MouseMapper

**把鼠标侧键映射为任意键盘按键。** 支持 macOS 和 Windows。

## 为什么做这个

如果你用罗技或其他品牌的多键鼠标，你大概率遇到过这些问题：

**Logitech Options+ 的痛点：**
- 侧键只能映射"前进/后退"这类浏览器操作，**不能映射为任意键盘按键**
- 想把侧键当 fn / Command / Alt 单独用？做不到
- 想映射 `Ctrl+C` 这样的组合键？对不起，不支持
- 软件本身 500MB+，开机自启吃内存，还有登录、同步、更新提示一堆烦人功能
- macOS 上经常和系统冲突，更新后映射丢失

**其他替代工具：** 要么收费（BetterTouchTool），要么配置复杂（Karabiner），要么只支持单平台。

**所以我做了 MouseMapper：**
- 一个 exe / 一个二进制，双击即用，零依赖
- 映射任意键盘按键，包括单独的修饰键（fn、Command/Win、Alt/Option、Shift、Ctrl）
- 支持组合键（`ctrl+c`、`shift+alt`、`command+space` 等）
- JSON 配置文件，一目了然，改完重启生效
- 整个程序不到 500KB，不联网，不登录，不更新，不烦你

## Download

**Windows:** [下载 MouseMapper.exe](https://github.com/vorojar/MouseMapper/releases) — 双击运行，自动后台托盘，自动开机启动。

**macOS:** 源码编译（见下方）。

## 快速开始

### Windows

1. 下载 `MouseMapper.exe`
2. 双击运行 → 自动在 exe 目录生成 `config.json` → 自动设置开机自启
3. 编辑 `config.json` 改映射，重启程序生效
4. 右下角托盘图标右键 → 管理自启 / 退出

### macOS

```bash
git clone https://github.com/vorojar/MouseMapper.git
cd MouseMapper
bash install.sh
```

首次运行需授权：`系统设置 → 隐私与安全 → 辅助功能`。

## 配置

两个平台共用同一套 `config.json` 格式：

```json
{
  "mappings": [
    {
      "button": 3,
      "key": "return",
      "action": "click"
    },
    {
      "button": 4,
      "key": "alt",
      "action": "hold"
    }
  ]
}
```

| 字段 | 说明 |
|------|------|
| `button` | 鼠标按键编号：`2`=中键，`3`=侧键后，`4`=侧键前 |
| `key` | 目标按键，支持 `+` 组合：`return`、`ctrl+c`、`shift+alt` |
| `action` | `"click"`（默认）按一下触发 / `"hold"` 按住持续 |

### 支持的按键

**修饰键：** `shift`、`control`/`ctrl`、`alt`/`option`、`command`/`win`、`caps_lock`（均支持 `left_`/`right_` 变体）

**macOS 专属：** `fn`

**功能键：** `f1`-`f12`

**常用键：** `escape`/`esc`、`return`/`enter`、`tab`、`space`、`backspace`/`delete`、`forward_delete`、`insert`

**导航键：** `up`、`down`、`left`、`right`、`home`、`end`、`page_up`、`page_down`

**字母/数字/符号：** `a`-`z`、`0`-`9`、`-`、`=`、`[`、`]`、`\`、`;`、`'`、`,`、`.`、`/`、`` ` ``

## 使用场景

- 侧键后 → `Enter`，拇指确认，写代码/聊天效率翻倍
- 侧键前 → `Alt`（按住模式），配合鼠标拖拽 = 窗口移动
- 中键 → `Escape`，随时取消操作
- 侧键 → `Ctrl+C` / `Ctrl+V`，单手复制粘贴
- 侧键 → `Command+Space`，一键呼出 Spotlight / 搜索

## 技术实现

### Windows
- C + Win32 API，~960 行代码
- `SetWindowsHookEx(WH_MOUSE_LL)` 全局钩子拦截
- `SendInput` 异步工作线程模拟按键（避免 hook 超时）
- 系统托盘图标 + 注册表开机自启

### macOS
- Swift，~500 行代码
- `CGEventTap` 会话级事件拦截
- 修饰键双通道：IOKit（系统级） + CGEvent（应用级），解决 macOS 合成事件被过滤的问题
- launchd 开机自启

## 构建

### Windows

需要 GCC (MinGW-w64)：

```bash
cd windows
build.bat
```

### macOS

需要 Swift 5.9+：

```bash
swift build -c release
```

## License

MIT
