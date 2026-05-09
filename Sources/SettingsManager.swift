import Foundation
import AppKit

struct CustomHotkey: Codable, Identifiable {
    var id: Int
    var actionId: String?
    var keyCode: UInt32
    var modifiers: UInt32
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var savePath: String { didSet { UserDefaults.standard.set(savePath, forKey: "savePath") } }
    @Published var isAwake: Bool = false
    
    // 3 Fixed Slots: Option+1, Option+2, Option+3
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
           let decoded = try? JSONDecoder().decode([CustomHotkey].self, from: data),
           decoded.count == 3 {
            self.customHotkeys = decoded
        } else {
            // Default 3 slots with fixed keys
            self.customHotkeys = [
                CustomHotkey(id: 1, actionId: "screenshot", keyCode: 18, modifiers: 0x0800), // Opt+1
                CustomHotkey(id: 2, actionId: "ocr", keyCode: 19, modifiers: 0x0800),        // Opt+2
                CustomHotkey(id: 3, actionId: "translate", keyCode: 20, modifiers: 0x0800)  // Opt+3
            ]
        }
    }
    
    func selectSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { self.savePath = url.path }
    }
    
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
        case "json_format": return "JSON专家工具"
        default: return "未选择功能"
        }
    }
    
    func getHotkeyString(for actionId: String) -> String? {
        if let hk = customHotkeys.first(where: { $0.actionId == actionId }) {
            return "⌥\(hk.id)"
        }
        return nil
    }
    
    func toggleAwake() { isAwake.toggle() }
    
    func pickColor() {
        NSColorSampler().show { color in
            if let color = color {
                let hex = String(format: "#%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255))
                NSPasteboard.general.clearContents(); NSPasteboard.general.setString(hex, forType: .string)
            }
        }
    }
    
    func smartJSONConvert() -> String? {
        let pb = NSPasteboard.general; guard let text = pb.string(forType: .string) else { return nil }
        if let data = text.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]), let prettyString = String(data: prettyData, encoding: .utf8) {
            pb.clearContents(); pb.setString(prettyString, forType: .string); return "JSON 已美化"
        }
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var dict: [String: String] = [:]; var isKV = false
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 { dict[parts[0]] = parts[1]; isKV = true }
        }
        if isKV, let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]), let kvString = String(data: data, encoding: .utf8) {
            pb.clearContents(); pb.setString(kvString, forType: .string); return "已转为 JSON 对象"
        }
        let wrapped = ["content": text]; if let data = try? JSONSerialization.data(withJSONObject: wrapped, options: [.prettyPrinted]), let wrappedString = String(data: data, encoding: .utf8) {
            pb.clearContents(); pb.setString(wrappedString, forType: .string); return "已包裹为 JSON 字符串"
        }
        return nil
    }
}
