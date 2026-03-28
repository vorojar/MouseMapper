#!/bin/bash

PLIST="$HOME/Library/LaunchAgents/com.local.mousemapper.plist"

echo "🖱 MouseMapper 卸载"

launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST"
rm -f "$HOME/.local/bin/mousemapper"

echo "✓ 已卸载（配置文件保留在 ~/.config/mousemapper/）"
