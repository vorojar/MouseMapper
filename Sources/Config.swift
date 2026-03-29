import Foundation
import CoreGraphics

// MARK: - 配置模型

struct Config: Codable {
    let mappings: [Mapping]
}

struct Mapping: Codable {
    let button: Int
    let key: String
    let action: String?

    var resolvedAction: ActionType {
        switch action?.lowercased() {
        case "hold": return .hold
        default: return .click
        }
    }
}

enum ActionType {
    case click
    case hold
}

// MARK: - 键码映射表

struct KeyMapping {
    let keyCode: CGKeyCode
    let flags: CGEventFlags
    let isModifier: Bool
}

let keyTable: [String: KeyMapping] = {
    var table: [String: KeyMapping] = [:]

    // 修饰键 — 只发送 flagsChanged 事件
    table["fn"]             = KeyMapping(keyCode: 0x3F, flags: .maskSecondaryFn, isModifier: true)
    table["left_command"]   = KeyMapping(keyCode: 0x37, flags: .maskCommand, isModifier: true)
    table["right_command"]  = KeyMapping(keyCode: 0x36, flags: .maskCommand, isModifier: true)
    table["command"]        = KeyMapping(keyCode: 0x37, flags: .maskCommand, isModifier: true)
    table["left_shift"]     = KeyMapping(keyCode: 0x38, flags: .maskShift, isModifier: true)
    table["right_shift"]    = KeyMapping(keyCode: 0x3C, flags: .maskShift, isModifier: true)
    table["shift"]          = KeyMapping(keyCode: 0x38, flags: .maskShift, isModifier: true)
    table["left_option"]    = KeyMapping(keyCode: 0x3A, flags: .maskAlternate, isModifier: true)
    table["right_option"]   = KeyMapping(keyCode: 0x3D, flags: .maskAlternate, isModifier: true)
    table["option"]         = KeyMapping(keyCode: 0x3A, flags: .maskAlternate, isModifier: true)
    table["left_control"]   = KeyMapping(keyCode: 0x3B, flags: .maskControl, isModifier: true)
    table["right_control"]  = KeyMapping(keyCode: 0x3E, flags: .maskControl, isModifier: true)
    table["control"]        = KeyMapping(keyCode: 0x3B, flags: .maskControl, isModifier: true)
    table["caps_lock"]      = KeyMapping(keyCode: 0x39, flags: .maskAlphaShift, isModifier: true)

    // 功能键
    table["f1"]  = KeyMapping(keyCode: 0x7A, flags: [], isModifier: false)
    table["f2"]  = KeyMapping(keyCode: 0x78, flags: [], isModifier: false)
    table["f3"]  = KeyMapping(keyCode: 0x63, flags: [], isModifier: false)
    table["f4"]  = KeyMapping(keyCode: 0x76, flags: [], isModifier: false)
    table["f5"]  = KeyMapping(keyCode: 0x60, flags: [], isModifier: false)
    table["f6"]  = KeyMapping(keyCode: 0x61, flags: [], isModifier: false)
    table["f7"]  = KeyMapping(keyCode: 0x62, flags: [], isModifier: false)
    table["f8"]  = KeyMapping(keyCode: 0x64, flags: [], isModifier: false)
    table["f9"]  = KeyMapping(keyCode: 0x65, flags: [], isModifier: false)
    table["f10"] = KeyMapping(keyCode: 0x6D, flags: [], isModifier: false)
    table["f11"] = KeyMapping(keyCode: 0x67, flags: [], isModifier: false)
    table["f12"] = KeyMapping(keyCode: 0x6F, flags: [], isModifier: false)

    // 常用键
    table["escape"]         = KeyMapping(keyCode: 0x35, flags: [], isModifier: false)
    table["return"]         = KeyMapping(keyCode: 0x24, flags: [], isModifier: false)
    table["tab"]            = KeyMapping(keyCode: 0x30, flags: [], isModifier: false)
    table["space"]          = KeyMapping(keyCode: 0x31, flags: [], isModifier: false)
    table["delete"]         = KeyMapping(keyCode: 0x33, flags: [], isModifier: false)
    table["forward_delete"] = KeyMapping(keyCode: 0x75, flags: [], isModifier: false)

    // 方向键
    table["up"]        = KeyMapping(keyCode: 0x7E, flags: [], isModifier: false)
    table["down"]      = KeyMapping(keyCode: 0x7D, flags: [], isModifier: false)
    table["left"]      = KeyMapping(keyCode: 0x7B, flags: [], isModifier: false)
    table["right"]     = KeyMapping(keyCode: 0x7C, flags: [], isModifier: false)
    table["home"]      = KeyMapping(keyCode: 0x73, flags: [], isModifier: false)
    table["end"]       = KeyMapping(keyCode: 0x77, flags: [], isModifier: false)
    table["page_up"]   = KeyMapping(keyCode: 0x74, flags: [], isModifier: false)
    table["page_down"] = KeyMapping(keyCode: 0x79, flags: [], isModifier: false)

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
        table[name] = KeyMapping(keyCode: code, flags: [], isModifier: false)
    }

    // 数字键 0-9
    let digits: [(String, CGKeyCode)] = [
        ("0", 0x1D), ("1", 0x12), ("2", 0x13), ("3", 0x14), ("4", 0x15),
        ("5", 0x17), ("6", 0x16), ("7", 0x1A), ("8", 0x1C), ("9", 0x19),
    ]
    for (name, code) in digits {
        table[name] = KeyMapping(keyCode: code, flags: [], isModifier: false)
    }

    // 符号键
    table["-"]  = KeyMapping(keyCode: 0x1B, flags: [], isModifier: false)
    table["="]  = KeyMapping(keyCode: 0x18, flags: [], isModifier: false)
    table["["]  = KeyMapping(keyCode: 0x21, flags: [], isModifier: false)
    table["]"]  = KeyMapping(keyCode: 0x1E, flags: [], isModifier: false)
    table["\\"] = KeyMapping(keyCode: 0x2A, flags: [], isModifier: false)
    table[";"]  = KeyMapping(keyCode: 0x29, flags: [], isModifier: false)
    table["'"]  = KeyMapping(keyCode: 0x27, flags: [], isModifier: false)
    table[","]  = KeyMapping(keyCode: 0x2B, flags: [], isModifier: false)
    table["."]  = KeyMapping(keyCode: 0x2F, flags: [], isModifier: false)
    table["/"]  = KeyMapping(keyCode: 0x2C, flags: [], isModifier: false)
    table["`"]  = KeyMapping(keyCode: 0x32, flags: [], isModifier: false)

    return table
}()

// MARK: - 配置加载

func loadConfig() -> Config {
    let cwd = FileManager.default.currentDirectoryPath + "/config.json"
    let execDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        .appendingPathComponent("config.json").path
    let userConfig = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/mousemapper/config.json").path

    let allPaths = [cwd, execDir, userConfig]

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

    print("✗ 未找到配置文件，使用默认配置（侧键后=回车, 侧键前=fn）")
    return Config(mappings: [
        Mapping(button: 3, key: "return", action: "click"),
        Mapping(button: 4, key: "fn", action: "hold"),
    ])
}
