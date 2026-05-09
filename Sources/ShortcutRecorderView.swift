import SwiftUI
import Carbon

struct ShortcutRecorderView: View {
    @Binding var hotkey: CustomHotkey
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
        .background(ShortcutHandlerView(isRecording: $isRecording, hotkey: $hotkey))
    }
    
    var displayString: String {
        guard let keyCode = hotkey.keyCode, let modifiers = hotkey.modifiers else { return "未设置" }
        return SettingsManager.shared.getHotkeyString(for: hotkey.actionId ?? "") ?? "Key(\(keyCode))"
    }
}

struct ShortcutHandlerView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var hotkey: CustomHotkey
    
    func makeNSView(context: Context) -> NSView {
        let view = ShortcutNSView()
        view.onKey = { code, mods in
            if isRecording {
                hotkey.keyCode = code
                hotkey.modifiers = mods
                isRecording = false
                // Notify to re-register
                DispatchQueue.main.async {
                    HotkeyManager.shared.refreshCustomHotkeys()
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
    override func viewDidMoveToWindow() { window?.makeFirstResponder(self) }
    
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
