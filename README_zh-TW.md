[English](README.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [日本語](README_ja.md) | [한국어](README_ko.md) | [Français](README_fr.md)

# MouseMapper

**將滑鼠側鍵映射為任意鍵盤按鍵。** 支援 macOS 與 Windows。

## 為什麼做這個

如果你用羅技或其他品牌的多鍵滑鼠，你大概率遇過這些問題：

**Logitech Options+ 的痛點：**
- 側鍵只能映射「上一頁/下一頁」這類瀏覽器操作，**無法映射為任意鍵盤按鍵**
- 想把側鍵當 fn / Command / Alt 單獨使用？辦不到
- 想映射 `Ctrl+C` 這樣的組合鍵？抱歉，不支援
- 軟體本身 500MB+，開機自啟吃記憶體，還有登入、同步、更新提示一堆煩人功能
- macOS 上經常和系統衝突，更新後映射遺失

**其他替代工具：** 要嘛收費（BetterTouchTool），要嘛設定複雜（Karabiner），要嘛只支援單平台。

**所以我做了 MouseMapper：**
- 一個 exe / 一個二進位檔，雙擊即用，零依賴
- 映射任意鍵盤按鍵，包括單獨的修飾鍵（fn、Command/Win、Alt/Option、Shift、Ctrl）
- 支援組合鍵（`ctrl+c`、`shift+alt`、`command+space` 等）
- JSON 設定檔，一目瞭然，改完重啟生效
- 整個程式不到 500KB，不連網，不登入，不更新，不煩你

## 下載

**Windows:** [下載 MouseMapper.exe](https://github.com/vorojar/MouseMapper/releases) — 雙擊執行，自動背景托盤，自動開機啟動。

**macOS:** 原始碼編譯（見下方）。

## 快速開始

### Windows

1. 下載 `MouseMapper.exe`
2. 雙擊執行 → 自動在 exe 目錄產生 `config.json` → 自動設定開機自啟
3. 編輯 `config.json` 修改映射，重啟程式生效
4. 右下角托盤圖示右鍵 → 管理自啟 / 結束

### macOS

```bash
git clone https://github.com/vorojar/MouseMapper.git
cd MouseMapper
bash install.sh
```

首次執行需授權：`系統設定 → 隱私與安全性 → 輔助使用`。

## 設定

兩個平台共用同一套 `config.json` 格式：

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

| 欄位 | 說明 |
|------|------|
| `button` | 滑鼠按鍵編號：`2`=中鍵，`3`=側鍵後，`4`=側鍵前 |
| `key` | 目標按鍵，支援 `+` 組合：`return`、`ctrl+c`、`shift+alt` |
| `action` | `"click"`（預設）按一下觸發 / `"hold"` 按住持續 |

### 支援的按鍵

**修飾鍵：** `shift`、`control`/`ctrl`、`alt`/`option`、`command`/`win`、`caps_lock`（均支援 `left_`/`right_` 變體）

**macOS 專屬：** `fn`

**功能鍵：** `f1`-`f12`

**常用鍵：** `escape`/`esc`、`return`/`enter`、`tab`、`space`、`backspace`/`delete`、`forward_delete`、`insert`

**導航鍵：** `up`、`down`、`left`、`right`、`home`、`end`、`page_up`、`page_down`

**字母/數字/符號：** `a`-`z`、`0`-`9`、`-`、`=`、`[`、`]`、`\`、`;`、`'`、`,`、`.`、`/`、`` ` ``

## 使用情境

- 側鍵後 → `Enter`，拇指確認，寫程式/聊天效率翻倍
- 側鍵前 → `Alt`（按住模式），搭配滑鼠拖曳 = 視窗移動
- 中鍵 → `Escape`，隨時取消操作
- 側鍵 → `Ctrl+C` / `Ctrl+V`，單手複製貼上
- 側鍵 → `Command+Space`，一鍵呼出 Spotlight / 搜尋

## 技術實作

### Windows
- C + Win32 API，約 960 行程式碼
- `SetWindowsHookEx(WH_MOUSE_LL)` 全域鉤子攔截
- `SendInput` 非同步工作執行緒模擬按鍵（避免 hook 逾時）
- 系統托盤圖示 + 登錄檔開機自啟

### macOS
- Swift，約 500 行程式碼
- `CGEventTap` 會話層級事件攔截
- 修飾鍵雙通道：IOKit（系統層級） + CGEvent（應用層級），解決 macOS 合成事件被過濾的問題
- launchd 開機自啟

## 建置

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
