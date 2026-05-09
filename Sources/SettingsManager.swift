import Foundation
import AppKit

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var savePath: String { didSet { UserDefaults.standard.set(savePath, forKey: "savePath") } }
    @Published var isAwake: Bool = false
    
    // Shortcuts Storage (keyCode, modifiers)
    @Published var screenshotHotkey: [UInt32] { didSet { UserDefaults.standard.set(screenshotHotkey, forKey: "screenshotHotkey") } }
    @Published var ocrHotkey: [UInt32] { didSet { UserDefaults.standard.set(ocrHotkey, forKey: "ocrHotkey") } }
    @Published var translateHotkey: [UInt32] { didSet { UserDefaults.standard.set(translateHotkey, forKey: "translateHotkey") } }
    
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
        
        // Defaults: Option(0x0800) + 1(18), 2(19), 3(20)
        self.screenshotHotkey = UserDefaults.standard.array(forKey: "screenshotHotkey") as? [UInt32] ?? [18, 0x0800]
        self.ocrHotkey = UserDefaults.standard.array(forKey: "ocrHotkey") as? [UInt32] ?? [19, 0x0800]
        self.translateHotkey = UserDefaults.standard.array(forKey: "translateHotkey") as? [UInt32] ?? [20, 0x0800]
    }
    
    func selectSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { self.savePath = url.path }
    }
    
    // Toolbox Helpers
    func toggleAwake() {
        isAwake.toggle()
        // Logic for Caffeine/NoSleep (iopm)
        if isAwake {
            // Start caffeine
        } else {
            // Stop caffeine
        }
    }
    
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
                pb.clearContents()
                pb.setString(prettyString, forType: .string)
                return true
            }
        } catch { return false }
        return false
    }
}
