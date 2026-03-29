# MouseMapper

A lightweight tool that remaps mouse side buttons to any keyboard key, including modifier keys and key combinations.

Built as a minimal alternative to Logitech Options+ — no GUI bloat, just a config file and a background process.

Supports **macOS** and **Windows**.

## Why

- Logitech Options+ is heavy and can't map side buttons to standalone modifier keys
- Neither macOS nor Windows has built-in mouse button remapping
- Existing tools are either paid or overly complex

## Features

- Remap any mouse button (side buttons, middle click) to any keyboard key
- **Standalone modifier keys** — map to fn, Command/Win, Option/Alt, Shift, Control
- **Key combinations** — `shift+command`, `ctrl+c`, `control+shift+a`, etc.
- **Hold mode** — hold mouse button = hold keyboard key
- **Click mode** — single mouse click triggers a key press
- JSON config, zero dependencies

## Download

**Windows:** [Download MouseMapper.exe](https://github.com/vorojar/MouseMapper/releases) — double-click to run, no install needed.

**macOS:** Build from source (see below).

## Config

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

### Fields

| Field | Description |
|-------|-------------|
| `button` | Mouse button number. `2`=middle, `3`=side back, `4`=side front |
| `key` | Target key or `+`-separated combo: `shift+command`, `ctrl+c` |
| `action` | `"click"` (default) or `"hold"` |

### Available keys

**Modifiers:** `shift`, `control`/`ctrl`, `alt`/`option`, `command`/`win`, `caps_lock` (with `left_`/`right_` variants)

**macOS only:** `fn`

**Function keys:** `f1`-`f12`

**Common:** `escape`/`esc`, `return`/`enter`, `tab`, `space`, `backspace`/`delete`, `forward_delete`, `insert`

**Navigation:** `up`, `down`, `left`, `right`, `home`, `end`, `page_up`, `page_down`

**Letters/digits/symbols:** `a`-`z`, `0`-`9`, `-`, `=`, `[`, `]`, `\`, `;`, `'`, `,`, `.`, `/`, `` ` ``

## Windows

Single exe, zero dependencies (~400KB).

- **Double-click** → auto-starts mapping + sets auto-start on boot
- **System tray** → right-click icon to toggle auto-start or exit
- **Config** → auto-generated at exe directory on first run

### Build from source

Requires GCC (MinGW-w64):

```bash
cd windows
build.bat
```

## macOS

~500 lines of Swift. Uses CGEventTap + IOKit dual-channel approach for system-level modifier key compatibility.

### Install

```bash
git clone https://github.com/vorojar/MouseMapper.git
cd MouseMapper
bash install.sh
```

**First run:** Grant Accessibility permission in `System Settings > Privacy & Security > Accessibility`.

### Usage

```bash
swift run                # run directly
bash install.sh          # install + auto-start via launchd
bash uninstall.sh        # uninstall
```

### How it works

1. **CGEventTap** intercepts mouse button events at the session level
2. For regular keys: sends `keyDown`/`keyUp` via CGEvent
3. For modifier keys: **dual-channel approach**
   - **IOKit** sets global modifier flags (recognized by system features like voice input)
   - **CGEvent** sends `flagsChanged` with keyCode (recognized by applications)

### Requirements

- macOS 13+, Swift 5.9+, Accessibility permission

## License

MIT
