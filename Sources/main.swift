import Foundation
import ApplicationServices

print("🖱 MouseMapper - 鼠标按键映射工具")
print("==================================\n")

// 检查辅助功能权限
let trusted = AXIsProcessTrusted()
if !trusted {
    print("⚠ 需要辅助功能权限！")
    print("  请前往: 系统设置 → 隐私与安全 → 辅助功能")
    print("  添加并启用本程序\n")

    // 弹出系统授权提示
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)

    print("已弹出授权提示，授权后请重新运行本程序。")
    exit(1)
}

// 加载配置
let config = loadConfig()

if config.mappings.isEmpty {
    print("⚠ 没有配置任何映射，退出。")
    exit(0)
}

// 启动事件监听
let tap = MouseEventTap(config: config)

// 处理 Ctrl+C 优雅退出
signal(SIGINT) { _ in
    print("\n✓ 已退出 MouseMapper")
    exit(0)
}

tap.start()
