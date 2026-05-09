import SwiftUI
import AppKit

// MARK: - FloatingWindowManager
// 每次 show() 都重建 contentViewController，确保 SwiftUI 视图持有最新内容
class FloatingWindowManager {
    static let shared = FloatingWindowManager()
    private var panel: NSPanel?

    func show(title: String, text: String) {
        DispatchQueue.main.async {
            // Always close the old panel first
            self.panel?.close()
            self.panel = nil

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 10), // height auto-sized
                styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            newPanel.level = .floating
            newPanel.backgroundColor = .clear
            newPanel.isMovableByWindowBackground = true
            newPanel.hasShadow = true
            newPanel.isReleasedWhenClosed = false

            // Build the SwiftUI view with concrete text values (no binding needed)
            let rootView = FloatingResultView(title: title, text: text) {
                self.panel?.close()
                self.panel = nil
            }
            let hosting = NSHostingController(rootView: rootView)
            hosting.view.setFrameSize(hosting.sizeThatFits(in: NSSize(width: 340, height: 800)))
            newPanel.contentViewController = hosting

            // Position: above mouse cursor, clamped to screen bounds
            let mouseLoc = NSEvent.mouseLocation
            let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            let winSize = hosting.view.frame.size
            var x = mouseLoc.x - winSize.width / 2
            var y = mouseLoc.y + 24

            if x < 8 { x = 8 }
            if x + winSize.width > screen.width - 8 { x = screen.width - winSize.width - 8 }
            if y + winSize.height > screen.height - 8 { y = mouseLoc.y - winSize.height - 24 }

            newPanel.setFrameOrigin(NSPoint(x: x, y: y))
            newPanel.makeKeyAndOrderFront(nil)
            self.panel = newPanel
        }
    }

    func hide() {
        DispatchQueue.main.async {
            self.panel?.close()
            self.panel = nil
        }
    }
}

// MARK: - FloatingResultView
// Pure value view — receives title and text as constants, no observable binding needed
struct FloatingResultView: View {
    let title: String
    let text: String
    let onClose: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Divider()

            // Translation result — always visible
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Footer
            HStack {
                if copied {
                    Label("已复制", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
                Spacer()
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                }) {
                    Label("复制", systemImage: "doc.on.doc")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}
