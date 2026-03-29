import CoreGraphics
import Foundation
import IOKit
import IOKit.hid

// MARK: - 鼠标事件拦截器

final class MouseEventTap {
    private let config: Config
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    static var heldKeys: [Int: KeyMapping] = [:]

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

    guard let keyMapping = keyTable[mapping.key.lowercased()] else {
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

/// 修饰键模拟：IOKit 设置全局 flags + CGEvent 发送 keyCode
/// IOKit 事件无合成标记(0x20000000)，可被系统级功能（如语音输入）识别
/// CGEvent 事件携带 keyCode，供普通应用识别具体哪个修饰键
private func postModifierEvent(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
    // IOKit: 设置全局修饰键状态
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

    // CGEvent: 发送带 keyCode 的 flagsChanged
    let source = CGEventSource(stateID: .hidSystemState)
    if let flagEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) {
        flagEvent.type = .flagsChanged
        flagEvent.flags = keyDown ? CGEventFlags(rawValue: flags.rawValue | 0x100) : CGEventFlags(rawValue: 0x100)
        flagEvent.post(tap: .cghidEventTap)
    }
}
