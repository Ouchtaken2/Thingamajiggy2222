import Foundation

enum TouchAction: String, CaseIterable, Codable {
    case up, down, left, right
    case a, b, x, y
    case l1, r1

    var title: String {
        switch self {
        case .up:    return "D-pad Up"
        case .down:  return "D-pad Down"
        case .left:  return "D-pad Left"
        case .right: return "D-pad Right"
        case .a:     return "Button A"
        case .b:     return "Button B"
        case .x:     return "Button X"
        case .y:     return "Button Y"
        case .l1:    return "Button L"
        case .r1:    return "Button R"
        }
    }
}

struct KeyOption: Identifiable {
    let id = UUID()
    let keyCode: Int
    let key: String
    let code: String
    let label: String

    var entry: TouchEntry {
        TouchEntry(keyCode: keyCode, key: key, code: code)
    }
}

/// Persists the on-screen button → keyboard-key mapping in UserDefaults.
final class TouchMappingStore {
    static let shared = TouchMappingStore()

    private let defaultsKey = "frickbears3.touch-mapping.v1"
    private let userDefaults: UserDefaults
    private(set) var entries: [TouchAction: TouchEntry]

    /// Called after any mapping change so views can refresh key labels.
    var onChange: (() -> Void)?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.entries = Self.defaultEntries

        if let data = userDefaults.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([String: TouchEntry].self, from: data) {
            for (raw, entry) in decoded {
                guard let action = TouchAction(rawValue: raw) else { continue }
                entries[action] = entry
            }
        }
    }

    func entry(for action: TouchAction) -> TouchEntry {
        entries[action] ?? Self.defaultEntries[action]!
    }

    func label(for action: TouchAction) -> String {
        let entry = entry(for: action)
        return Self.availableKeys.first { $0.keyCode == entry.keyCode && $0.code == entry.code }?.label
            ?? (entry.key == " " ? "Space" : entry.key.uppercased())
    }

    func set(_ option: KeyOption, for action: TouchAction) {
        entries[action] = option.entry
        save()
    }

    func resetToDefaults() {
        entries = Self.defaultEntries
        save()
    }

    private func save() {
        var raw: [String: TouchEntry] = [:]
        for (action, entry) in entries { raw[action.rawValue] = entry }
        guard let data = try? JSONEncoder().encode(raw) else { return }
        userDefaults.set(data, forKey: defaultsKey)
        onChange?()
    }

    static let defaultEntries: [TouchAction: TouchEntry] = [
        .up:    TouchEntry(keyCode: 38, key: "ArrowUp",    code: "ArrowUp"),
        .down:  TouchEntry(keyCode: 40, key: "ArrowDown",  code: "ArrowDown"),
        .left:  TouchEntry(keyCode: 37, key: "ArrowLeft",  code: "ArrowLeft"),
        .right: TouchEntry(keyCode: 39, key: "ArrowRight", code: "ArrowRight"),
        .a:     TouchEntry(keyCode: 32, key: " ",          code: "Space"),
        .b:     TouchEntry(keyCode: 27, key: "Escape",     code: "Escape"),
        .x:     TouchEntry(keyCode: 69, key: "e",          code: "KeyE"),
        .y:     TouchEntry(keyCode: 9,  key: "Tab",        code: "Tab"),
        .l1:    TouchEntry(keyCode: 81, key: "q",          code: "KeyQ"),
        .r1:    TouchEntry(keyCode: 70, key: "f",          code: "KeyF")
    ]

    static let availableKeys: [KeyOption] = {
        var keys: [KeyOption] = [
            KeyOption(keyCode: 38, key: "ArrowUp",    code: "ArrowUp",    label: "↑  Up"),
            KeyOption(keyCode: 40, key: "ArrowDown",  code: "ArrowDown",  label: "↓  Down"),
            KeyOption(keyCode: 37, key: "ArrowLeft",  code: "ArrowLeft",  label: "←  Left"),
            KeyOption(keyCode: 39, key: "ArrowRight", code: "ArrowRight", label: "→  Right"),
            KeyOption(keyCode: 32, key: " ",          code: "Space",      label: "Space"),
            KeyOption(keyCode: 13, key: "Enter",      code: "Enter",      label: "Enter"),
            KeyOption(keyCode: 27, key: "Escape",     code: "Escape",     label: "Escape"),
            KeyOption(keyCode: 9,  key: "Tab",        code: "Tab",        label: "Tab"),
            KeyOption(keyCode: 16, key: "Shift",      code: "ShiftLeft",  label: "Shift"),
            KeyOption(keyCode: 17, key: "Control",    code: "ControlLeft",label: "Ctrl"),
            KeyOption(keyCode: 18, key: "Alt",        code: "AltLeft",    label: "Alt")
        ]

        for index in 0..<26 {
            let letter = Character(UnicodeScalar(65 + index)!)
            let lower = String(letter).lowercased()
            keys.append(KeyOption(
                keyCode: 65 + index,
                key: lower,
                code: "Key\(letter)",
                label: String(letter)
            ))
        }

        for digit in 0...9 {
            keys.append(KeyOption(
                keyCode: 48 + digit,
                key: String(digit),
                code: "Digit\(digit)",
                label: String(digit)
            ))
        }

        return keys
    }()
}
