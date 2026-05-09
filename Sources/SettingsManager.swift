import Foundation
import AppKit

struct CustomHotkey: Codable, Identifiable {
    var id: Int
    var actionId: String? // e.g. "screenshot", "ocr", etc.
    var keyCode: UInt32?
    var modifiers: UInt32?
    
    var isConfigured: Bool { keyCode != nil && actionId != nil }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var savePath: String { didSet { UserDefaults.standard.set(savePath, forKey: "savePath") } }
    @Published var isAwake: Bool = false
    
    // Five custom dynamic hotkeys
    @Published var customHotkeys: [CustomHotkey] {
        didSet {
            if let data = try? JSONEncoder().encode(customHotkeys) {
                UserDefaults.standard.set(data, forKey: "customHotkeys")
            }
        }
    }
    
    var saveUrl: URL {
        let url = URL(fileURLWithPath: savePath).appendingPathComponent("Test_Downloads")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    init() {
        let defaultPath = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first ?? NSHomeDirectory()
        self.savePath = UserDefaults.standard.string(forKey: "savePath") ?? defaultPath
        
        if let data = UserDefaults.standard.data(forKey: "customHotkeys"),
           let decoded = try? JSONDecoder().decode([CustomHotkey].self, from: data) {
            self.customHotkeys = decoded
        } else {
            // Default 5 empty slots
            self.customHotkeys = (1...5).map { CustomHotkey(id: $0) }
            // Populate first 3 with defaults for backward compatibility/quick start
            self.customHotkeys[0].actionId = "screenshot"; self.customHotkeys[0].keyCode = 18; self.customHotkeys[0].modifiers = 0x0800 // Opt+1
            self.customHotkeys[1].actionId = "ocr"; self.customHotkeys[1].keyCode = 19; self.customHotkeys[1].modifiers = 0x0800        // Opt+2
            self.customHotkeys[2].actionId = "translate"; self.customHotkeys[2].keyCode = 20; self.customHotkeys[2].modifiers = 0x0800  // Opt+3
        }
    }
    
    func selectSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { self.savePath = url.path }
    }
    
    // Action Labels Mapping
    func getActionName(for actionId: String?) -> String {
        switch actionId {
        case "screenshot": return "屏幕截图"
        case "ocr": return "文字识别"
        case "translate": return "多语言翻译"
        case "clean_cache": return "库缓存清理"
        case "normalize_audio": return "音频标准化"
        case "xml_downgrade": return "XML版本降级"
        case "image_process": return "万能图像处理"
        case "media_download": return "全网媒体解析"
        case "speech_to_text": return "语音听写"
        case "doc_convert": return "宇宙文档转换"
        case "merge_docs": return "全能文档合并"
        case "pick_color": return "屏幕取色"
        case "anti_sleep": return "屏幕防休眠"
        case "science_calc": return "科学计算器"
        case "unit_calc": return "单位换算"
        case "currency_calc": return "汇率系统"
        case "json_format": return "JSON格式化"
        default: return "未选择功能"
        }
    }
    
    // Hotkey Display String
    func getHotkeyString(for actionId: String) -> String? {
        if let hk = customHotkeys.first(where: { $0.actionId == actionId && $0.keyCode != nil }) {
            return stringFor(keyCode: hk.keyCode!, modifiers: hk.modifiers ?? 0)
        }
        return nil
    }
    
    private func stringFor(keyCode: UInt32, modifiers: UInt32) -> String {
        var str = ""
        if modifiers & 0x0100 != 0 { str += "⌘" }
        if modifiers & 0x0200 != 0 { str += "⇧" }
        if modifiers & 0x0400 != 0 { str += "⌃" }
        if modifiers & 0x0800 != 0 { str += "⌥" }
        
        let charMap: [UInt32: String] = [
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
            0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J", 40: "K", 37: "L", 46: "M",
            45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X", 16: "Y", 6: "Z",
            49: "Space", 36: "Return", 48: "Tab", 53: "Esc", 51: "Del", 126: "↑", 125: "↓", 123: "←", 124: "→"
        ]
        str += charMap[keyCode] ?? "Key(\(keyCode))"
        return str
    }
    
    // Toolbox Helpers
    func toggleAwake() { isAwake.toggle() }
    
    func pickColor() {
        NSColorSampler().show { color in
            if let color = color {
                let hex = String(format: "#%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255))
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(hex, forType: .string)
            }
        }
    }
    
    func formatJSON() -> Bool {
        let pb = NSPasteboard.general
        guard let text = pb.string(forType: .string) else { return false }
        guard let data = text.data(using: .utf8) else { return false }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            if let prettyString = String(data: prettyData, encoding: .utf8) {
                pb.clearContents(); pb.setString(prettyString, forType: .string)
                return true
            }
        } catch { return false }
        return false
    }
}
