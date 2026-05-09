import Cocoa
import SwiftUI

struct HistoryItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let timestamp: String
}

class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()
    
    @Published var history: [HistoryItem] = []
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    func start() {
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let newString = pasteboard.string(forType: .string) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: Date())
            
            DispatchQueue.main.async {
                // Avoid consecutive duplicates
                if self.history.first?.content != newString {
                    let item = HistoryItem(content: newString, timestamp: timeString)
                    self.history.insert(item, at: 0)
                    if self.history.count > 50 {
                        self.history.removeLast()
                    }
                }
            }
        }
    }
    
    func clear() {
        history.removeAll()
    }
}
