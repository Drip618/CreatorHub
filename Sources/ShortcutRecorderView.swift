import SwiftUI
import Carbon

struct ShortcutRecorderView: View {
    @Binding var keyData: [UInt32] // [keyCode, modifiers]
    @State private var isRecording = false
    
    var body: some View {
        Button(action: { isRecording.toggle() }) {
            HStack(spacing: 4) {
                if isRecording {
                    Text("请按下按键...")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                } else {
                    Text(displayString)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(ShortcutHandlerView(isRecording: $isRecording, keyData: $keyData))
    }
    
    var displayString: String {
        let keyCode = keyData[0]
        let modifiers = keyData[1]
        
        var str = ""
        if modifiers & UInt32(0x100) != 0 { str += "⌘" }
        if modifiers & UInt32(0x0800) != 0 { str += "⌥" }
        if modifiers & UInt32(0x0200) != 0 { str += "⇧" }
        if modifiers & UInt32(0x0400) != 0 { str += "⌃" }
        
        str += keyName(for: keyCode)
        return str.isEmpty ? "未设置" : str
    }
    
    func keyName(for keyCode: UInt32) -> String {
        // Simple mapping for common keys
        switch keyCode {
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 17: return "T"
        case 32: return "U"
        case 9: return "V"
        case 13: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 6: return "Z"
        case 49: return "Space"
        default: return "Key\(keyCode)"
        }
    }
}

struct ShortcutHandlerView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var keyData: [UInt32]
    
    func makeNSView(context: Context) -> NSView {
        let view = ShortcutNSView()
        view.onKey = { code, mods in
            if isRecording {
                keyData = [code, mods]
                isRecording = false
                // Notify AppDelegate to re-register
                DispatchQueue.main.async {
                    (NSApp.delegate as? AppDelegate)?.setupHotkeys()
                }
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class ShortcutNSView: NSView {
    var onKey: ((UInt32, UInt32) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        var modifiers: UInt32 = 0
        if event.modifierFlags.contains(.command) { modifiers |= 0x100 }
        if event.modifierFlags.contains(.option) { modifiers |= 0x0800 }
        if event.modifierFlags.contains(.shift) { modifiers |= 0x0200 }
        if event.modifierFlags.contains(.control) { modifiers |= 0x0400 }
        
        onKey?(keyCode, modifiers)
    }
}
