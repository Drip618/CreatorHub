import Foundation
import AppKit

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var savePath: String {
        didSet {
            UserDefaults.standard.set(savePath, forKey: "savePath")
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
    }
    
    func selectSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "选择 (Select)"
        
        if panel.runModal() == .OK, let url = panel.url {
            self.savePath = url.path
        }
    }
}
