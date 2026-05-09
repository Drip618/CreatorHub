import SwiftUI
import AppKit

class FloatingContent: ObservableObject {
    @Published var title: String = ""
    @Published var text: String = ""
    @Published var isShowing: Bool = false
}

class FloatingWindowManager {
    static let shared = FloatingWindowManager()
    var window: NSPanel?
    let content = FloatingContent()
    
    func show(title: String, text: String) {
        DispatchQueue.main.async {
            self.content.title = title
            self.content.text = text
            self.content.isShowing = true
            
            if self.window == nil {
                let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 340, height: 220),
                                    styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                                    backing: .buffered, defer: false)
                panel.level = .floating
                panel.backgroundColor = .clear
                panel.isMovableByWindowBackground = true
                panel.hasShadow = true
                panel.contentViewController = NSHostingController(rootView: FloatingResultView(content: self.content) {
                    self.hide()
                })
                self.window = panel
            }
            
            let mouseLoc = NSEvent.mouseLocation
            let screen = NSScreen.main?.frame ?? .zero
            
            // Calculate position: Center horizontally to mouse, and show ABOVE the mouse
            let windowWidth: CGFloat = 340
            let windowHeight: CGFloat = 220
            
            var x = mouseLoc.x - (windowWidth / 2)
            var y = mouseLoc.y + 20 // 20px above mouse
            
            // Boundary checks
            if x < 0 { x = 10 }
            if x + windowWidth > screen.width { x = screen.width - windowWidth - 10 }
            if y + windowHeight > screen.height { y = mouseLoc.y - windowHeight - 20 }
            
            self.window?.setFrameOrigin(NSPoint(x: x, y: y))
            self.window?.makeKeyAndOrderFront(nil)
            
            // Auto-hide after 15 seconds if not interacted with? Maybe not.
        }
    }
    
    func hide() {
        DispatchQueue.main.async {
            self.window?.orderOut(nil)
            self.content.isShowing = false
        }
    }
}

struct FloatingResultView: View {
    @ObservedObject var content: FloatingContent
    let onClose: () -> Void
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(content.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            ScrollView {
                Text(content.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(4)
            }
            .frame(maxHeight: 300)
            
            HStack {
                if copied {
                    Text("已复制到剪贴板")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
                Spacer()
                Button(action: {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(content.text, forType: .string)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { copied = false } }
                }) {
                    Label("复制", systemImage: "doc.on.doc")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .shadow(radius: 10)
    }
}
