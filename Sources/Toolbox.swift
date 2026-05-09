import SwiftUI
import AppKit
import IOKit.pwr_mgt
import UniformTypeIdentifiers

class ToolboxManager: ObservableObject {
    static let shared = ToolboxManager()
    
    @Published var isAwake = false
    private var assertionID: IOPMAssertionID = 0
    
    func formatJSON() -> Bool {
        let pb = NSPasteboard.general
        guard let string = pb.string(forType: .string),
              let data = string.data(using: .utf8) else { return false }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            if let prettyString = String(data: prettyData, encoding: .utf8) {
                pb.clearContents()
                pb.setString(prettyString, forType: .string)
                return true
            }
        } catch { return false }
        return false
    }
    
    func toggleAwake() {
        if isAwake {
            IOPMAssertionRelease(assertionID)
            isAwake = false
        } else {
            let reason = "MacCaptureHub Keep Awake" as CFString
            let success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                                      IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                      reason, &assertionID)
            if success == kIOReturnSuccess { isAwake = true }
        }
    }
    
    func pickColor() {
        DispatchQueue.main.async {
            NSColorSampler().show { selectedColor in
                if let color = selectedColor {
                    let hex = color.toHex()
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(hex, forType: .string)
                }
            }
        }
    }
}

extension NSColor {
    func toHex() -> String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else { return "#FFFFFF" }
        let red = Int(round(rgbColor.redComponent * 0xFF))
        let green = Int(round(rgbColor.greenComponent * 0xFF))
        let blue = Int(round(rgbColor.blueComponent * 0xFF))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

struct ToolItem {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
}

struct ToolboxView: View {
    @ObservedObject var lang = LanguageManager.shared
    @ObservedObject var manager = ToolboxManager.shared
    @ObservedObject var speechManager = SpeechManager.shared
    @ObservedObject var ocrManager = OCRManager.shared
    @ObservedObject var imageProcessor = ImageProcessor.shared
    @ObservedObject var ultimateManager = UltimateManager.shared
    @State private var showMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    ToolboxSection(title: "🖥️ 屏幕与图像", tools: [
                        ToolItem(icon: "macwindow.badge.plus", title: "屏幕截图", subtitle: "Option+1", action: { triggerScreenshot() }),
                        ToolItem(icon: "text.viewfinder", title: ocrManager.isRecognizing ? "..." : "文字识别", subtitle: "Option+2", action: {
                            ocrManager.recognizeTextFromScreen { result in showMessage = result != nil ? "识别完成" : "识别失败" }
                        }),
                        ToolItem(icon: "lock.shield", title: "图片隐私净化", subtitle: "", action: {
                            let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseFiles = true; panel.canChooseDirectories = false
                            if #available(macOS 11.0, *) { panel.allowedContentTypes = [.image] }
                            if panel.runModal() == .OK, !panel.urls.isEmpty {
                                ultimateManager.stripEXIF(from: panel.urls) { count in showMessage = "成功净化 \(count) 张图片！" }
                            }
                        }),
                        ToolItem(icon: imageProcessor.isProcessing ? "photo.on.rectangle.angled" : "photo.stack", title: imageProcessor.isProcessing ? "处理中..." : "万能图像处理", subtitle: "", action: { showImageProcessorDialog() }),
                        ToolItem(icon: "pencil.and.outline", title: "图像编辑与裁剪", subtitle: "", action: { openPreviewEdit() })
                    ])
                    
                    ToolboxSection(title: "🎬 多媒体引擎", tools: [
                        ToolItem(icon: DownloadManager.shared.isDownloading ? "arrow.down.circle.fill" : "arrow.down.circle", title: DownloadManager.shared.isDownloading ? "解析下载中..." : "全网媒体解析", subtitle: "", action: { showDownloadDialog() }),
                        ToolItem(icon: ultimateManager.isProcessing ? "hourglass" : "film.circle.fill", title: ultimateManager.isProcessing ? "底层处理中..." : "终极视频工坊", subtitle: "", action: { showFFmpegDialog() })
                    ])
                    
                    ToolboxSection(title: "📄 文档创作流", tools: [
                        ToolItem(icon: speechManager.isRecording ? "mic.fill" : "mic", title: speechManager.isRecording ? "正在倾听..." : "语音听写", subtitle: "", action: {
                            speechManager.toggleRecording(); if speechManager.isRecording { showMessage = "正在倾听中..." }
                        }),
                        ToolItem(icon: TranslateManager.shared.isTranslating ? "globe.americas" : "character.book.closed", title: TranslateManager.shared.isTranslating ? "..." : "多语言翻译", subtitle: "Option+3", action: {
                            TranslateManager.shared.translateClipboard { result in
                                if let res = result { FloatingWindowManager.shared.show(title: "翻译结果", text: res) }
                                else { showMessage = "请先复制或选中要翻译的文字" }
                            }
                        }),
                        ToolItem(icon: ultimateManager.isProcessing ? "hourglass" : "doc.text.magnifyingglass", title: ultimateManager.isProcessing ? "转换中..." : "宇宙文档转换", subtitle: "", action: { showPandocDialog() }),
                        ToolItem(icon: DocumentManager.shared.isProcessing ? "doc.on.doc.fill" : "doc.on.doc", title: DocumentManager.shared.isProcessing ? "..." : "智能 PDF 拼接", subtitle: "", action: { mergePDFs() })
                    ])
                    
                    ToolboxSection(title: "📊 智能生产力", tools: [
                        ToolItem(icon: "plus.forwardslash.minus", title: "万能计算与换算", subtitle: "", action: { showSmartCalc() }),
                        ToolItem(icon: "eyedropper", title: "屏幕取色", subtitle: "", action: { manager.pickColor(); showMessage = "颜色已复制" }),
                        ToolItem(icon: manager.isAwake ? "sun.max.fill" : "moon.zzz", title: manager.isAwake ? "防休眠(已开启)" : "屏幕防休眠", subtitle: "", action: { manager.toggleAwake() }),
                        ToolItem(icon: "curlybraces", title: "JSON 格式化", subtitle: "", action: { showMessage = manager.formatJSON() ? "JSON 已格式化" : "非有效 JSON" })
                    ])
                }
                .padding(20)
            }
            
            if let msg = showMessage {
                Text(msg).font(.subheadline).foregroundColor(.green).padding()
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showMessage = nil } }
            }
        }
    }
    
    // Dialogs
    private func showSmartCalc() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                              styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.center(); window.title = "万能计算与换算"
        window.contentView = NSHostingView(rootView: SmartCalculatorView())
        window.makeKeyAndOrderFront(nil)
    }
    
    private func showImageProcessorDialog() {
        let alert = NSAlert()
        alert.messageText = "智能图像工坊"; alert.informativeText = "请选择对图片执行的操作："
        alert.addButton(withTitle: "精准宫格切图"); alert.addButton(withTitle: "可视化去水印/修补")
        alert.addButton(withTitle: "智能证件照底色"); alert.addButton(withTitle: "转为 HEIC 格式"); alert.addButton(withTitle: "取消")
        
        switch alert.runModal() {
        case .alertFirstButtonReturn: if let action = showGridSlicerConfig() { pickAndProcessImages(action: action) }
        case .alertSecondButtonReturn: showVisualSelection(url: nil, isVideo: false)
        case .alertThirdButtonReturn: pickAndProcessImages(action: .idPhotoMaker)
        case NSApplication.ModalResponse(rawValue: 1003): pickAndProcessImages(action: .convertFormat(.heic))
        default: break
        }
    }
    
    private func showFFmpegDialog() {
        let alert = NSAlert()
        alert.messageText = "终极影视工坊"; alert.informativeText = "请选择多媒体处理操作："
        alert.addButton(withTitle: "可视化去水印"); alert.addButton(withTitle: "音频净化(去广告人声)")
        alert.addButton(withTitle: "H.264 无损高压缩"); alert.addButton(withTitle: "更多 (转码/GIF/抽帧)"); alert.addButton(withTitle: "取消")
        
        switch alert.runModal() {
        case .alertFirstButtonReturn: showVisualSelection(url: nil, isVideo: true)
        case .alertSecondButtonReturn: pickAndProcessVideo(action: .audioPurify)
        case .alertThirdButtonReturn: pickAndProcessVideo(action: .compress)
        case NSApplication.ModalResponse(rawValue: 1003): showFFmpegAdvanceDialog()
        default: break
        }
    }
    
    private func showVisualSelection(url: URL?, isVideo: Bool) {
        if let targetUrl = url {
            presentVisualSelectionWindow(url: targetUrl, isVideo: isVideo)
        } else {
            let panel = NSOpenPanel()
            if #available(macOS 11.0, *) { panel.allowedContentTypes = isVideo ? [.movie] : [.image] }
            if panel.runModal() == .OK, let selectedUrl = panel.url {
                presentVisualSelectionWindow(url: selectedUrl, isVideo: isVideo)
            }
        }
    }
    
    private func presentVisualSelectionWindow(url: URL, isVideo: Bool) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 650),
                              styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.center(); window.title = isVideo ? "视频去水印 - 框选区域" : "图片去水印 - 框选区域"
        let view = WatermarkSelectionView(url: url, isVideo: isVideo, onConfirm: { rects in
            window.close()
            if isVideo { ultimateManager.processVideo(url: url, action: .delogo(rects: rects)) { _, msg in showMessage = msg } }
            else { ultimateManager.inpaintImage(url: url, rects: rects) { _, msg in showMessage = msg } }
        }, onCancel: { window.close() })
        window.contentView = NSHostingView(rootView: view); window.makeKeyAndOrderFront(nil)
    }
    
    // Helpers
    private func triggerScreenshot() {
        let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Screenshot_\(Int(Date().timeIntervalSince1970)).png")
        let task = Process(); task.launchPath = "/usr/sbin/screencapture"; task.arguments = ["-i", tempUrl.path]
        task.terminationHandler = { _ in
            if FileManager.default.fileExists(atPath: tempUrl.path) {
                let openTask = Process(); openTask.launchPath = "/usr/bin/open"; openTask.arguments = ["-a", "Preview", tempUrl.path]; openTask.launch()
            }
        }; task.launch(); showMessage = "请画框截取..."
    }
    
    private func openPreviewEdit() {
        let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = false
        if #available(macOS 11.0, *) { panel.allowedContentTypes = [.image] }
        if panel.runModal() == .OK, let url = panel.url {
            let newUrl = SettingsManager.shared.saveUrl.appendingPathComponent("图片编辑_\(Int(Date().timeIntervalSince1970)).\(url.pathExtension)")
            try? FileManager.default.copyItem(at: url, to: newUrl)
            let task = Process(); task.launchPath = "/usr/bin/open"; task.arguments = ["-a", "Preview", newUrl.path]; task.launch()
            showMessage = "已创建副本，可进行编辑保存。"
        }
    }
    
    private func showDownloadDialog() {
        let alert = NSAlert(); alert.messageText = "全网媒体解析下载"; alert.informativeText = "请粘贴视频或图片链接："
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24)); alert.accessoryView = input
        alert.addButton(withTitle: "极速下载"); alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn {
            DownloadManager.shared.downloadMedia(from: input.stringValue, saveTo: SettingsManager.shared.saveUrl) { success, msg in showMessage = msg }
        }
    }
    
    private func pickAndProcessImages(action: ImageAction) {
        let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseDirectories = false; panel.canChooseFiles = true
        if #available(macOS 11.0, *) { panel.allowedContentTypes = [.image] }
        if panel.runModal() == .OK, !panel.urls.isEmpty {
            imageProcessor.processImages(urls: panel.urls, action: action, saveTo: SettingsManager.shared.saveUrl) { success in
                showMessage = success ? "图片处理成功！" : "处理失败"
            }
        }
    }
    
    private func pickAndProcessVideo(action: UltimateManager.FFmpegAction) {
        let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = false
        if #available(macOS 11.0, *) { panel.allowedContentTypes = [.movie, .audio, .video] }
        if panel.runModal() == .OK, let url = panel.url {
            ultimateManager.processVideo(url: url, action: action) { success, msg in showMessage = msg }
        }
    }
    
    private func showFFmpegAdvanceDialog() {
        let alert = NSAlert(); alert.messageText = "万能格式转换与提取"; alert.addButton(withTitle: "生成高质量 GIF")
        alert.addButton(withTitle: "提取无损音频 (MP3)"); alert.addButton(withTitle: "转码为 MP4"); alert.addButton(withTitle: "取消")
        switch alert.runModal() {
        case .alertFirstButtonReturn: pickAndProcessVideo(action: .toGIF)
        case .alertSecondButtonReturn: pickAndProcessVideo(action: .extractAudio)
        case .alertThirdButtonReturn: pickAndProcessVideo(action: .transcodeToMP4)
        default: break
        }
    }
    
    private func showPandocDialog() {
        let alert = NSAlert(); alert.messageText = "宇宙文档转化"; alert.addButton(withTitle: "MD 转 Word")
        alert.addButton(withTitle: "Word 转 MD"); alert.addButton(withTitle: "HTML 转 MD"); alert.addButton(withTitle: "取消")
        var action: UltimateManager.PandocAction?
        switch alert.runModal() {
        case .alertFirstButtonReturn: action = .mdToWord
        case .alertSecondButtonReturn: action = .wordToMd
        case .alertThirdButtonReturn: action = .htmlToMd
        default: return
        }
        if let act = action {
            let panel = NSOpenPanel(); panel.canChooseFiles = true; if panel.runModal() == .OK, let url = panel.url {
                ultimateManager.processDocument(url: url, action: act) { _, msg in showMessage = msg }
            }
        }
    }
    
    private func mergePDFs() {
        let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; if #available(macOS 11.0, *) { panel.allowedContentTypes = [.pdf] }
        if panel.runModal() == .OK, panel.urls.count > 1 {
            DocumentManager.shared.mergePDFs(urls: panel.urls, saveTo: SettingsManager.shared.saveUrl) { success in
                showMessage = success ? "PDF 合并成功！" : "合并失败"
            }
        }
    }
    
    private func showGridSlicerConfig() -> ImageAction? {
        let alert = NSAlert(); alert.messageText = "精准宫格切图配置"; alert.addButton(withTitle: "确定"); alert.addButton(withTitle: "取消")
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 100))
        let popup = NSPopUpButton(frame: NSRect(x: 100, y: 70, width: 140, height: 24))
        popup.addItems(withTitles: ["自定义", "2宫格(1x2)", "2宫格(2x1)", "3宫格(1x3)", "3宫格(3x1)", "4宫格(2x2)", "6宫格(2x3)", "9宫格(3x3)", "25宫格(5x5)", "32宫格(4x8)"]); popup.selectItem(at: 7)
        let rIn = NSTextField(string: "3"); rIn.frame = NSRect(x: 80, y: 30, width: 50, height: 20)
        let cIn = NSTextField(string: "3"); cIn.frame = NSRect(x: 80, y: 0, width: 50, height: 20)
        view.addSubview(popup); view.addSubview(rIn); view.addSubview(cIn)
        alert.accessoryView = view
        if alert.runModal() == .alertFirstButtonReturn {
            var r = 1, c = 1
            switch popup.indexOfSelectedItem {
            case 1: r = 1; c = 2; case 2: r = 2; c = 1; case 3: r = 1; c = 3; case 4: r = 3; c = 1; case 5: r = 2; c = 2
            case 6: r = 2; c = 3; case 7: r = 3; c = 3; case 8: r = 5; c = 5; case 9: r = 4; c = 8
            default: r = Int(rIn.stringValue) ?? 1; c = Int(cIn.stringValue) ?? 1
            }
            return .sliceGrid(rows: r, columns: c)
        }
        return nil
    }
}

struct ToolboxSection: View {
    let title: String
    let tools: [ToolItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundColor(.secondary).padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(0..<tools.count, id: \.self) { index in
                    ToolRow(item: tools[index])
                    if index < tools.count - 1 { Divider().padding(.leading, 42) }
                }
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5)).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1))
        }
    }
}

struct ToolRow: View {
    let item: ToolItem
    @State private var isHovered = false
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon).font(.system(size: 16)).foregroundColor(.accentColor).frame(width: 24)
                Text(item.title).font(.body).foregroundColor(.primary)
                Spacer()
                if !item.subtitle.isEmpty {
                    Text(item.subtitle).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 3).background(Color.primary.opacity(0.1)).cornerRadius(6)
                }
            }
            .padding(.vertical, 10).padding(.horizontal, 12)
            .background(isHovered ? Color.primary.opacity(0.05) : Color.clear).contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { h in isHovered = h; if h { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() } }
    }
}
