import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = ServiceProvider()
        NSUpdateDynamicServices()
        
        setupMenu()
        // PermissionManager.shared.checkAndRequestPermissions()
        
        setupStatusBar()
        setupHotkeys()
        
        // Setup Clipboard Monitor
        ClipboardMonitor.shared.start()
    }
    
    func setupMenu() {
        let appMenu = NSMenu()
        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        
        editMenu.addItem(withTitle: "Undo", action: NSSelectorFromString("undo:"), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: NSSelectorFromString("redo:"), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: NSSelectorFromString("cut:"), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: NSSelectorFromString("copy:"), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: NSSelectorFromString("paste:"), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: NSSelectorFromString("selectAll:"), keyEquivalent: "a")
        
        editItem.submenu = editMenu
        appMenu.addItem(editItem)
        
        NSApp.mainMenu = appMenu
    }
    
    func setupHotkeys() {
        HotkeyManager.shared.refreshCustomHotkeys()
    }
    
    func translateSelectedText() {
        let pb = NSPasteboard.general
        let oldCount = pb.changeCount
        
        // Simulate Cmd+C to copy selected text
        let source = CGEventSource(stateID: .hidSystemState)
        if let copyKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true),
           let copyKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) {
            copyKeyDown.flags = .maskCommand
            copyKeyUp.flags = .maskCommand
            copyKeyDown.post(tap: .cghidEventTap)
            copyKeyUp.post(tap: .cghidEventTap)
        }
        
        // Poll for clipboard update (up to 1.5s: 15 attempts x 0.1s)
        // Use translateText() so we don't overwrite the user's clipboard
        func pollClipboard(attempts: Int) {
            if pb.changeCount != oldCount,
               let text = pb.string(forType: .string),
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Clipboard was updated — translate the fresh selection
                TranslateManager.shared.translateText(text) { result in
                    if let res = result {
                        let shortSource = text.count > 40 ? String(text.prefix(40)) + "..." : text
                        FloatingWindowManager.shared.show(title: shortSource, text: res)
                    } else {
                        FloatingWindowManager.shared.show(title: "翻译失败", text: "请检查网络连接，或确认已开启辅助功能权限。")
                    }
                }
            } else if attempts < 15 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    pollClipboard(attempts: attempts + 1)
                }
            } else {
                // Timeout — fall back to whatever is currently on clipboard
                guard let text = pb.string(forType: .string),
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    FloatingWindowManager.shared.show(
                        title: "无法获取选中内容",
                        text: "请先在任意应用中选中文字，再按 Option+3。\n注：首次使用需在「系统设置 → 隐私与安全性 → 辅助功能」中开启 Creator Hub 权限。"
                    )
                    return
                }
                TranslateManager.shared.translateText(text) { result in
                    if let res = result {
                        FloatingWindowManager.shared.show(title: "剪贴板翻译", text: res)
                    } else {
                        FloatingWindowManager.shared.show(title: "翻译失败", text: "请检查网络连接。")
                    }
                }
            }
        }
        
        // Start polling after a brief delay to let the system process Cmd+C
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            pollClipboard(attempts: 0)
        }
    }
    
    func triggerScreenshot() {
        let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Screenshot_\(Int(Date().timeIntervalSince1970)).png")
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", tempUrl.path]
        task.terminationHandler = { _ in
            if FileManager.default.fileExists(atPath: tempUrl.path) {
                let openTask = Process()
                openTask.launchPath = "/usr/bin/open"
                openTask.arguments = ["-a", "Preview", tempUrl.path]
                openTask.launch()
            }
        }
        task.launch()
    }
    
    func showSmartCalc(tab: Int) {
        let titles = ["科学计算器", "万能单位换算器", "全球实时汇率系统"]
        let heights: [CGFloat] = [780, 680, 680]
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: heights[tab]),
                              styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.center(); window.title = titles[tab]; window.titlebarAppearsTransparent = true; window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true; window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SmartCalculatorView(initialTab: tab))
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    
    func setupStatusBar() {
        
        let contentView = ContentView()
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 440, height: 720)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Use a highly premium macOS native symbol
            if let image = NSImage(systemSymbolName: "cube.transparent.fill", accessibilityDescription: "Creator Hub") {
                let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
                button.image = image.withSymbolConfiguration(config)
            } else {
                button.title = "🎬"
            }
            button.action = #selector(handleIconClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func handleIconClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "退出 Creator Hub (Quit)", action: #selector(quitApp), keyEquivalent: "q"))
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
        } else {
            togglePopover(sender)
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}

class ServiceProvider: NSObject {
    @objc func handleServicesMessage(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let items = pboard.pasteboardItems else { return }
        var urls = [URL]()
        for item in items {
            if let string = item.string(forType: .fileURL), let url = URL(string: string) {
                urls.append(url)
            }
        }
        
        guard !urls.isEmpty else { return }
        
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            let isMovie = urls.contains { ["mp4", "mov", "mkv", "avi", "webm"].contains($0.pathExtension.lowercased()) }
            let isPDF = urls.contains { $0.pathExtension.lowercased() == "pdf" }
            let isImage = urls.contains { ["png", "jpg", "jpeg", "heic", "gif", "webp"].contains($0.pathExtension.lowercased()) }
            
            let alert = NSAlert()
            alert.messageText = "Creator Hub (快捷操作)"
            alert.informativeText = "收到 \(urls.count) 个文件，请选择快捷处理方式："
            
            if isMovie {
                alert.addButton(withTitle: "生成高质量 GIF")
                alert.addButton(withTitle: "无损高压缩")
                alert.addButton(withTitle: "万能转码为 MP4")
                alert.addButton(withTitle: "取消")
                let resp = alert.runModal()
                if resp == .alertFirstButtonReturn {
                    UltimateManager.shared.processVideo(url: urls[0], action: .toGIF) { _,_ in }
                } else if resp == .alertSecondButtonReturn {
                    UltimateManager.shared.processVideo(url: urls[0], action: .compress) { _,_ in }
                } else if resp == .alertThirdButtonReturn {
                    UltimateManager.shared.processVideo(url: urls[0], action: .transcodeToMP4) { _,_ in }
                }
            } else if urls.count > 1 {
                alert.addButton(withTitle: "智能合并所选文档/表格")
                alert.addButton(withTitle: "取消")
                if alert.runModal() == .alertFirstButtonReturn {
                    DocumentManager.shared.mergeFiles(urls: urls) { _, _ in }
                }
            } else if isImage {
                alert.addButton(withTitle: "净化隐私定位 (EXIF)")
                alert.addButton(withTitle: "转为 JPG")
                alert.addButton(withTitle: "转为 HEIC")
                alert.addButton(withTitle: "取消")
                switch alert.runModal() {
                case .alertFirstButtonReturn:
                    UltimateManager.shared.stripEXIF(from: urls) { _ in }
                case .alertSecondButtonReturn:
                    ImageProcessor.shared.processImages(urls: urls, action: .convertFormat(.jpeg), saveTo: SettingsManager.shared.saveUrl) { _ in }
                case .alertThirdButtonReturn:
                    ImageProcessor.shared.processImages(urls: urls, action: .convertFormat(.heic), saveTo: SettingsManager.shared.saveUrl) { _ in }
                default: break
                }
            } else {
                alert.informativeText = "文档或未识别文件请在主界面转换。"
                alert.addButton(withTitle: "好的")
                alert.runModal()
            }
        }
    }
}
