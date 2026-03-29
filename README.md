# MouseMapper

A lightweight macOS tool that remaps mouse side buttons to any keyboard key, including modifier keys like fn, Command, Option, and key combinations like `Shift+Command`.

Built as a minimal alternative to Logitech Options+ — no GUI, no bloat, just a config file and a background process.

## Why

- Logitech Options+ is heavy and can't map side buttons to standalone modifier keys (fn, Command, etc.)
- macOS has no built-in mouse button remapping
- Existing tools are either paid or overly complex

## Features

- Remap any mouse button (side buttons, middle click, etc.) to any keyboard key
- **Standalone modifier keys** — map to fn, Command, Option, Shift, Control alone
- **Key combinations** — `shift+command`, `command+c`, `control+shift+a`, etc.
- **Hold mode** — hold mouse button = hold keyboard key (e.g., hold side button for Option)
- **Click mode** — single mouse click triggers a key press
- **System-level compatibility** — works with macOS voice input, Spotlight, and other system features (via IOKit + CGEvent dual-channel approach)
- JSON config, zero dependencies, ~500 lines of Swift

## Install

```bash
git clone https://github.com/vorojar/MouseMapper.git
cd MouseMapper
bash install.sh
```

This compiles the binary, installs to `~/.local/bin/`, and sets up auto-start via launchd.

**First run:** macOS will prompt you to grant Accessibility permission in `System Settings > Privacy & Security > Accessibility`.

## Config

Config file locations (checked in order):
1. Current working directory: `./config.json`
2. Next to the binary
3. `~/.config/mousemapper/config.json`

### Example

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
      "key": "option",
      "action": "hold"
    }
  ]
}
```

### Fields

| Field | Description |
|-------|-------------|
| `button` | Mouse button number. `2`=middle, `3`=side back, `4`=side front. Run with unknown buttons to see their numbers in the log. |
| `key` | Target key. Single key or `+`-separated combo: `command`, `shift+command`, `control+z` |
| `action` | `"click"` = one press per click (default). `"hold"` = key held while mouse button held. |

### Available keys

**Modifiers:** `fn`, `command`/`left_command`/`right_command`, `shift`/`left_shift`/`right_shift`, `option`/`left_option`/`right_option`, `control`/`left_control`/`right_control`, `caps_lock`

**Function keys:** `f1`-`f12`

**Common:** `escape`, `return`, `tab`, `space`, `delete`, `forward_delete`

**Arrows:** `up`, `down`, `left`, `right`, `home`, `end`, `page_up`, `page_down`

**Letters/digits/symbols:** `a`-`z`, `0`-`9`, `-`, `=`, `[`, `]`, `\`, `;`, `'`, `,`, `.`, `/`, `` ` ``

## Usage

```bash
# Run directly
swift run

# Or after install
mousemapper

# Manage the background service
launchctl unload ~/Library/LaunchAgents/com.local.mousemapper.plist  # stop
launchctl load ~/Library/LaunchAgents/com.local.mousemapper.plist    # start

# Uninstall
bash uninstall.sh
```

## How it works

1. **CGEventTap** intercepts mouse button events at the session level
2. For regular keys: sends standard `keyDown`/`keyUp` via CGEvent
3. For modifier keys: uses a **dual-channel approach**
   - **IOKit** sets the global modifier flags (no synthetic event marker, recognized by system features like voice input)
   - **CGEvent** sends `flagsChanged` with the correct keyCode (recognized by applications)

This dual approach solves a macOS quirk where CGEvent-only synthetic modifier events carry a `0x20000000` flag that system-level features (like voice input) use to filter out fake key presses.

## Requirements

- macOS 13+
- Swift 5.9+
- Accessibility permission

## License

MIT
