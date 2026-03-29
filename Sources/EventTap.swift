import CoreGraphics
import Foundation

// MARK: - 鼠标事件拦截器

final class MouseEventTap {
    private let config: Config
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// 当前被按住的映射键（用于 hold 模式松开时释放）
    static var heldKeys: [Int: KeyMapping] = [:]

    init(config: Config) {
        self.config = config
    }

    func start() {
        // 监听所有鼠标按键事件（otherMouse = 非左右键，即侧键/中键）
        let eventMask: CGEventMask =
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue)

        // 将 config 传入回调（通过 userInfo 指针）
        let configPtr = Unmanaged.passRetained(ConfigBox(config)).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: mouseCallback,
            userInfo: configPtr
        ) else {
            print("✗ 无法创建事件监听器！请检查「系统设置 → 隐私与安全 → 辅助功能」权限")
            exit(1)
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("✓ 事件监听已启动")
        printMappings()
        print("按 Ctrl+C 退出\n")

        CFRunLoopRun()
    }

    private func printMappings() {
        for m in config.mappings {
            let buttonName = mouseButtonName(m.button)
            let actionName = m.resolvedAction == .hold ? "按住" : "点击"
            print("  \(buttonName) → \(m.key) (\(actionName)模式)")
        }
    }

    private func mouseButtonName(_ button: Int) -> String {
        switch button {
        case 2: return "中键"
        case 3: return "侧键后(Button3)"
        case 4: return "侧键前(Button4)"
        default: return "Button\(button)"
        }
    }
}

// 用于通过 userInfo 指针传递配置
private class ConfigBox {
    let config: Config
    init(_ config: Config) { self.config = config }
}

// MARK: - CGEvent 回调（C 函数指针）

private func mouseCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // 事件tap被系统禁用时重新启用
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        return Unmanaged.passUnretained(event)
    }

    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let configBox = Unmanaged<ConfigBox>.fromOpaque(userInfo).takeUnretainedValue()
    let buttonNumber = Int(event.getIntegerValueField(.mouseEventButtonNumber))

    // 查找匹配的映射
    guard let mapping = configBox.config.mappings.first(where: { $0.button == buttonNumber }) else {
        return Unmanaged.passUnretained(event)  // 无映射，放行原始事件
    }

    guard let keyMapping = keyTable[mapping.key.lowercased()] else {
        print("⚠ 未知键名: \(mapping.key)")
        return Unmanaged.passUnretained(event)
    }

    let isDown = (type == .otherMouseDown)

    switch mapping.resolvedAction {
    case .hold:
        if isDown {
            sendKeyEvent(keyMapping: keyMapping, keyDown: true)
            MouseEventTap.heldKeys[buttonNumber] = keyMapping
        } else {
            if let held = MouseEventTap.heldKeys[buttonNumber] {
                sendKeyEvent(keyMapping: held, keyDown: false)
                MouseEventTap.heldKeys.removeValue(forKey: buttonNumber)
            }
        }

    case .click:
        if isDown {
            sendKeyEvent(keyMapping: keyMapping, keyDown: true)
            sendKeyEvent(keyMapping: keyMapping, keyDown: false)
        }
    }

    return nil  // 吞掉原始鼠标事件
}

// MARK: - 模拟键盘事件

private func sendKeyEvent(keyMapping: KeyMapping, keyDown: Bool) {
    let source = CGEventSource(stateID: .hidSystemState)

    if let keyCode = keyMapping.keyCode {
        // 发送键盘事件
        if let keyEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) {
            if keyMapping.flags != [] {
                keyEvent.flags = keyDown ? keyMapping.flags : []
            }
            keyEvent.post(tap: .cghidEventTap)
        }
    }

    // 对于修饰键，额外发送 flagsChanged 事件确保系统识别
    if keyMapping.flags != [], let keyCode = keyMapping.keyCode {
        if let flagEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) {
            flagEvent.type = .flagsChanged
            flagEvent.flags = keyDown ? keyMapping.flags : []
            flagEvent.post(tap: .cghidEventTap)
        }
    }
}
