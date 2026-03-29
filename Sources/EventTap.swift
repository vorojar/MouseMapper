import CoreGraphics
import Foundation
import IOKit
import IOKit.hid

// MARK: - 鼠标事件拦截器

final class MouseEventTap {
    private let config: Config
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// hold 模式下当前按住的键（支持组合键）
    static var heldKeys: [Int: [KeyMapping]] = [:]

    init(config: Config) {
        self.config = config
    }

    func start() {
        let mouseMask: CGEventMask =
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue)

        let configPtr = Unmanaged.passRetained(ConfigBox(config)).toOpaque()

        guard let mouseTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mouseMask,
            callback: mouseCallback,
            userInfo: configPtr
        ) else {
            print("✗ 无法创建事件监听器！请检查「系统设置 → 隐私与安全 → 辅助功能」权限")
            exit(1)
        }

        eventTap = mouseTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: mouseTap, enable: true)

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

private class ConfigBox {
    let config: Config
    init(_ config: Config) { self.config = config }
}

/// 解析键名（支持 "shift+command+a" 组合键）
private func resolveKeys(_ keyString: String) -> [KeyMapping]? {
    let parts = keyString.lowercased().split(separator: "+").map(String.init)
    var mappings: [KeyMapping] = []
    for part in parts {
        let trimmed = part.trimmingCharacters(in: .whitespaces)
        guard let km = keyTable[trimmed] else { return nil }
        mappings.append(km)
    }
    return mappings.isEmpty ? nil : mappings
}

// MARK: - CGEvent 回调

private func mouseCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        return Unmanaged.passUnretained(event)
    }

    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let configBox = Unmanaged<ConfigBox>.fromOpaque(userInfo).takeUnretainedValue()
    let buttonNumber = Int(event.getIntegerValueField(.mouseEventButtonNumber))

    guard let mapping = configBox.config.mappings.first(where: { $0.button == buttonNumber }) else {
        return Unmanaged.passUnretained(event)
    }

    guard let keyMappings = resolveKeys(mapping.key) else {
        return Unmanaged.passUnretained(event)
    }

    let isDown = (type == .otherMouseDown)

    switch mapping.resolvedAction {
    case .hold:
        if isDown {
            for km in keyMappings { sendKeyEvent(keyMapping: km, keyDown: true) }
            MouseEventTap.heldKeys[buttonNumber] = keyMappings
        } else {
            if let held = MouseEventTap.heldKeys[buttonNumber] {
                for km in held.reversed() { sendKeyEvent(keyMapping: km, keyDown: false) }
                MouseEventTap.heldKeys.removeValue(forKey: buttonNumber)
            }
        }

    case .click:
        if isDown {
            for km in keyMappings { sendKeyEvent(keyMapping: km, keyDown: true) }
            for km in keyMappings.reversed() { sendKeyEvent(keyMapping: km, keyDown: false) }
        }
    }

    return nil
}

// MARK: - 模拟键盘事件

private func sendKeyEvent(keyMapping: KeyMapping, keyDown: Bool) {
    if keyMapping.isModifier {
        postModifierEvent(keyCode: keyMapping.keyCode, flags: keyMapping.flags, keyDown: keyDown)
    } else {
        let source = CGEventSource(stateID: .hidSystemState)
        if let keyEvent = CGEvent(keyboardEventSource: source, virtualKey: keyMapping.keyCode, keyDown: keyDown) {
            keyEvent.post(tap: .cghidEventTap)
        }
    }
}

/// 修饰键：IOKit 设置全局 flags + CGEvent 发送 keyCode
private func postModifierEvent(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
    var connect: io_connect_t = 0
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
    if service != 0 {
        if IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect) == KERN_SUCCESS {
            var event = NXEventData()
            let pressFlags = UInt32(flags.rawValue & 0x00FFFFFF) | 0x100
            let postFlags: UInt32 = keyDown ? pressFlags : 0x100
            IOHIDPostEvent(connect, UInt32(NX_FLAGSCHANGED), IOGPoint(x: 0, y: 0), &event,
                          UInt32(kNXEventDataVersion), IOOptionBits(postFlags), IOOptionBits(kIOHIDSetGlobalEventFlags))
            IOServiceClose(connect)
        }
        IOObjectRelease(service)
    }

    let source = CGEventSource(stateID: .hidSystemState)
    if let flagEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) {
        flagEvent.type = .flagsChanged
        flagEvent.flags = keyDown ? CGEventFlags(rawValue: flags.rawValue | 0x100) : CGEventFlags(rawValue: 0x100)
        flagEvent.post(tap: .cghidEventTap)
    }
}
