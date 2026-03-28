#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/mousemapper"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.local.mousemapper.plist"

echo "🖱 MouseMapper 安装脚本"
echo "======================"

# 编译
echo "→ 编译中..."
swift build -c release --quiet
BINARY=".build/release/MouseMapper"

if [ ! -f "$BINARY" ]; then
    echo "✗ 编译失败"
    exit 1
fi
echo "✓ 编译成功"

# 安装二进制
mkdir -p "$INSTALL_DIR"
cp "$BINARY" "$INSTALL_DIR/mousemapper"
chmod +x "$INSTALL_DIR/mousemapper"
echo "✓ 已安装到 $INSTALL_DIR/mousemapper"

# 安装配置文件
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    cp config.json "$CONFIG_DIR/config.json"
    echo "✓ 已创建配置文件 $CONFIG_DIR/config.json"
else
    echo "→ 配置文件已存在，跳过"
fi

# 创建 launchd plist（开机自启）
mkdir -p "$PLIST_DIR"
cat > "$PLIST_DIR/$PLIST_NAME" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.mousemapper</string>
    <key>ProgramArguments</key>
    <array>
        <string>${INSTALL_DIR}/mousemapper</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${HOME}/.config/mousemapper/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/.config/mousemapper/stderr.log</string>
</dict>
</plist>
EOF
echo "✓ 已创建 launchd 配置 $PLIST_DIR/$PLIST_NAME"

# 加载服务
launchctl unload "$PLIST_DIR/$PLIST_NAME" 2>/dev/null || true
launchctl load "$PLIST_DIR/$PLIST_NAME"
echo "✓ 服务已启动"

echo ""
echo "=================================="
echo "安装完成！"
echo ""
echo "配置文件: $CONFIG_DIR/config.json"
echo "日志文件: $CONFIG_DIR/stdout.log"
echo ""
echo "常用命令:"
echo "  停止服务: launchctl unload ~/Library/LaunchAgents/$PLIST_NAME"
echo "  启动服务: launchctl load ~/Library/LaunchAgents/$PLIST_NAME"
echo "  卸载:     bash uninstall.sh"
echo ""
echo "⚠ 首次运行需要在「系统设置 → 隐私与安全 → 辅助功能」中授权"
