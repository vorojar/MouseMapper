[English](README.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [日本語](README_ja.md) | [한국어](README_ko.md) | [Français](README_fr.md)

# MouseMapper

**Map mouse side buttons to any keyboard key.** Supports macOS and Windows.

## Why This Exists

If you use a Logitech or other multi-button mouse, you've probably run into these problems:

**Pain points with Logitech Options+:**
- Side buttons can only be mapped to browser actions like Forward/Back — **no arbitrary keyboard key mapping**
- Want to use a side button as fn / Command / Alt on its own? Can't do it
- Want to map `Ctrl+C` as a combo? Sorry, not supported
- The software itself is 500MB+, auto-starts, eats memory, and nags you with login, sync, and update prompts
- On macOS it frequently conflicts with the system, and mappings get lost after updates

**Other alternatives:** Either paid (BetterTouchTool), overly complex to configure (Karabiner), or single-platform only.

**So I built MouseMapper:**
- One exe / one binary, double-click to run, zero dependencies
- Map any keyboard key, including standalone modifiers (fn, Command/Win, Alt/Option, Shift, Ctrl)
- Key combos supported (`ctrl+c`, `shift+alt`, `command+space`, etc.)
- JSON config file, dead simple, edit and restart to apply
- Entire program under 500KB — no network, no login, no updates, no hassle

## Download

**Windows:** [Download MouseMapper.exe](https://github.com/vorojar/MouseMapper/releases) — Double-click to run, auto system tray, auto startup.

**macOS:** Build from source (see below).

## Quick Start

### Windows

1. Download `MouseMapper.exe`
2. Double-click to run → auto-generates `config.json` in the exe directory → auto-sets startup
3. Edit `config.json` to change mappings, restart the program to apply
4. Right-click the tray icon in the bottom-right → manage startup / exit

### macOS

```bash
git clone https://github.com/vorojar/MouseMapper.git
cd MouseMapper
bash install.sh
```

First run requires permission: `System Settings → Privacy & Security → Accessibility`.

## Configuration

Both platforms share the same `config.json` format:

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

| Field | Description |
|-------|-------------|
| `button` | Mouse button number: `2`=middle, `3`=side back, `4`=side forward |
| `key` | Target key, supports `+` combos: `return`, `ctrl+c`, `shift+alt` |
| `action` | `"click"` (default) fires once / `"hold"` holds while pressed |

### Supported Keys

**Modifiers:** `shift`, `control`/`ctrl`, `alt`/`option`, `command`/`win`, `caps_lock` (all support `left_`/`right_` variants)

**macOS only:** `fn`

**Function keys:** `f1`-`f12`

**Common keys:** `escape`/`esc`, `return`/`enter`, `tab`, `space`, `backspace`/`delete`, `forward_delete`, `insert`

**Navigation:** `up`, `down`, `left`, `right`, `home`, `end`, `page_up`, `page_down`

**Letters/Numbers/Symbols:** `a`-`z`, `0`-`9`, `-`, `=`, `[`, `]`, `\`, `;`, `'`, `,`, `.`, `/`, `` ` ``

## Use Cases

- Side back → `Enter` — thumb confirm, doubles coding/chat efficiency
- Side forward → `Alt` (hold mode) — combine with mouse drag = window move
- Middle → `Escape` — instant cancel
- Side button → `Ctrl+C` / `Ctrl+V` — one-hand copy/paste
- Side button → `Command+Space` — instant Spotlight / search

## Technical Details

### Windows
- C + Win32 API, ~960 lines of code
- `SetWindowsHookEx(WH_MOUSE_LL)` global hook interception
- `SendInput` on async worker thread for key simulation (avoids hook timeout)
- System tray icon + registry auto-start

### macOS
- Swift, ~500 lines of code
- `CGEventTap` session-level event interception
- Dual-channel modifier keys: IOKit (system-level) + CGEvent (app-level), solving macOS synthetic event filtering
- launchd auto-start

## Build

### Windows

Requires GCC (MinGW-w64):

```bash
cd windows
build.bat
```

### macOS

Requires Swift 5.9+:

```bash
swift build -c release
```

## License

MIT
