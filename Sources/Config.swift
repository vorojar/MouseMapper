import Foundation
import CoreGraphics

// MARK: - 配置模型

struct Config: Codable {
    let mappings: [Mapping]
}

struct Mapping: Codable {
    let button: Int        // 鼠标按键编号: 3=中键, 4=侧键后, 5=侧键前
    let key: String        // 映射目标键名
    let action: String?    // "click"(默认) 或 "hold"（按住鼠标=按住键）

    var resolvedAction: ActionType {
        switch action?.lowercased() {
        case "hold": return .hold
        default: return .click
        }
    }
}

enum ActionType {
    case click  // 鼠标按下时触发一次按键
    case hold   // 鼠标按住期间持续按住键
}

// MARK: - 键码映射表

/// 将配置文件中的键名解析为 (CGKeyCode, CGEventFlags)
/// 修饰键只需要 flags，普通键需要 keyCode
struct KeyMapping {
    let keyCode: CGKeyCode?
    let flags: CGEventFlags

    /// 是否为纯修饰键（fn, command, shift 等）
    var isModifierOnly: Bool { keyCode == nil }
}

let keyTable: [String: KeyMapping] = {
    var table: [String: KeyMapping] = [:]

    // 修饰键 — 模拟时需要同时发送对应的 keyCode
    table["fn"]             = KeyMapping(keyCode: 0x3F, flags: .maskSecondaryFn)
    table["left_command"]   = KeyMapping(keyCode: 0x37, flags: .maskCommand)
    table["right_command"]  = KeyMapping(keyCode: 0x36, flags: .maskCommand)
    table["command"]        = KeyMapping(keyCode: 0x37, flags: .maskCommand)
    table["left_shift"]     = KeyMapping(keyCode: 0x38, flags: .maskShift)
    table["right_shift"]    = KeyMapping(keyCode: 0x3C, flags: .maskShift)
    table["shift"]          = KeyMapping(keyCode: 0x38, flags: .maskShift)
    table["left_option"]    = KeyMapping(keyCode: 0x3A, flags: .maskAlternate)
    table["right_option"]   = KeyMapping(keyCode: 0x3D, flags: .maskAlternate)
    table["option"]         = KeyMapping(keyCode: 0x3A, flags: .maskAlternate)
    table["left_control"]   = KeyMapping(keyCode: 0x3B, flags: .maskControl)
    table["right_control"]  = KeyMapping(keyCode: 0x3E, flags: .maskControl)
    table["control"]        = KeyMapping(keyCode: 0x3B, flags: .maskControl)
    table["caps_lock"]      = KeyMapping(keyCode: 0x39, flags: .maskAlphaShift)

    // 功能键
    table["f1"]  = KeyMapping(keyCode: 0x7A, flags: [])
    table["f2"]  = KeyMapping(keyCode: 0x78, flags: [])
    table["f3"]  = KeyMapping(keyCode: 0x63, flags: [])
    table["f4"]  = KeyMapping(keyCode: 0x76, flags: [])
    table["f5"]  = KeyMapping(keyCode: 0x60, flags: [])
    table["f6"]  = KeyMapping(keyCode: 0x61, flags: [])
    table["f7"]  = KeyMapping(keyCode: 0x62, flags: [])
    table["f8"]  = KeyMapping(keyCode: 0x64, flags: [])
    table["f9"]  = KeyMapping(keyCode: 0x65, flags: [])
    table["f10"] = KeyMapping(keyCode: 0x6D, flags: [])
    table["f11"] = KeyMapping(keyCode: 0x67, flags: [])
    table["f12"] = KeyMapping(keyCode: 0x6F, flags: [])

    // 常用键
    table["escape"]      = KeyMapping(keyCode: 0x35, flags: [])
    table["return"]      = KeyMapping(keyCode: 0x24, flags: [])
    table["tab"]         = KeyMapping(keyCode: 0x30, flags: [])
    table["space"]       = KeyMapping(keyCode: 0x31, flags: [])
    table["delete"]      = KeyMapping(keyCode: 0x33, flags: [])
    table["forward_delete"] = KeyMapping(keyCode: 0x75, flags: [])

    // 方向键
    table["up"]    = KeyMapping(keyCode: 0x7E, flags: [])
    table["down"]  = KeyMapping(keyCode: 0x7D, flags: [])
    table["left"]  = KeyMapping(keyCode: 0x7B, flags: [])
    table["right"] = KeyMapping(keyCode: 0x7C, flags: [])

    table["home"]      = KeyMapping(keyCode: 0x73, flags: [])
    table["end"]       = KeyMapping(keyCode: 0x77, flags: [])
    table["page_up"]   = KeyMapping(keyCode: 0x74, flags: [])
    table["page_down"] = KeyMapping(keyCode: 0x79, flags: [])

    // 字母键 a-z
    let letters: [(String, CGKeyCode)] = [
        ("a", 0x00), ("b", 0x0B), ("c", 0x08), ("d", 0x02), ("e", 0x0E),
        ("f", 0x03), ("g", 0x05), ("h", 0x04), ("i", 0x22), ("j", 0x26),
        ("k", 0x28), ("l", 0x25), ("m", 0x2E), ("n", 0x2D), ("o", 0x1F),
        ("p", 0x23), ("q", 0x0C), ("r", 0x0F), ("s", 0x01), ("t", 0x11),
        ("u", 0x20), ("v", 0x09), ("w", 0x0D), ("x", 0x07), ("y", 0x10),
        ("z", 0x06),
    ]
    for (name, code) in letters {
        table[name] = KeyMapping(keyCode: code, flags: [])
    }

    // 数字键 0-9
    let digits: [(String, CGKeyCode)] = [
        ("0", 0x1D), ("1", 0x12), ("2", 0x13), ("3", 0x14), ("4", 0x15),
        ("5", 0x17), ("6", 0x16), ("7", 0x1A), ("8", 0x1C), ("9", 0x19),
    ]
    for (name, code) in digits {
        table[name] = KeyMapping(keyCode: code, flags: [])
    }

    // 符号键
    table["-"]  = KeyMapping(keyCode: 0x1B, flags: [])
    table["="]  = KeyMapping(keyCode: 0x18, flags: [])
    table["["]  = KeyMapping(keyCode: 0x21, flags: [])
    table["]"]  = KeyMapping(keyCode: 0x1E, flags: [])
    table["\\"] = KeyMapping(keyCode: 0x2A, flags: [])
    table[";"]  = KeyMapping(keyCode: 0x29, flags: [])
    table["'"]  = KeyMapping(keyCode: 0x27, flags: [])
    table[","]  = KeyMapping(keyCode: 0x2B, flags: [])
    table["."]  = KeyMapping(keyCode: 0x2F, flags: [])
    table["/"]  = KeyMapping(keyCode: 0x2C, flags: [])
    table["`"]  = KeyMapping(keyCode: 0x32, flags: [])

    return table
}()

// MARK: - 配置加载

func loadConfig() -> Config {
    let configPaths = [
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/mousemapper/config.json").path,
        Bundle.main.bundlePath + "/../config.json",
    ]

    // 找当前可执行文件同目录的 config.json
    let execURL = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
    let execConfig = execURL.appendingPathComponent("config.json").path
    let allPaths = [execConfig] + configPaths

    for path in allPaths {
        if FileManager.default.fileExists(atPath: path),
           let data = FileManager.default.contents(atPath: path) {
            do {
                let config = try JSONDecoder().decode(Config.self, from: data)
                print("✓ 已加载配置: \(path)")
                return config
            } catch {
                print("✗ 配置文件解析失败 (\(path)): \(error)")
            }
        }
    }

    print("✗ 未找到配置文件，使用默认配置（侧键后=Command, 侧键前=回车）")
    return Config(mappings: [
        Mapping(button: 4, key: "left_command", action: "hold"),
        Mapping(button: 5, key: "return", action: "click"),
    ])
}
