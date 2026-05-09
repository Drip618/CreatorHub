import SwiftUI
import AppKit
import IOKit.pwr_mgt
import UniformTypeIdentifiers

class ToolboxManager: ObservableObject {
    static let shared = ToolboxManager()
    
    @Published var isAwake = false
    private var assertionID: IOPMAssertionID = 0
    
    // JSON Formatter
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
        } catch {
            return false
        }
        return false
    }
    
    // Keep Awake
    func toggleAwake() {
        if isAwake {
            IOPMAssertionRelease(assertionID)
            isAwake = false
        } else {
            let reasonForActivity = "MacCaptureHub Keep Awake" as CFString
            let success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                                      IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                      reasonForActivity,
                                                      &assertionID)
            if success == kIOReturnSuccess {
                isAwake = true
            }
        }
    }
    
    // Color Picker
    func pickColor() {
        DispatchQueue.main.async {
            let colorSampler = NSColorSampler()
            colorSampler.show { selectedColor in
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
                    
                    // 1. Screen & Image
                    ToolboxSection(title: "🖥️ 屏幕与图像", tools: [
                        ToolItem(icon: "macwindow.badge.plus", title: "屏幕截图", subtitle: "Option+1", action: {
                            let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Screenshot_\(Int(Date().timeIntervalSince1970)).png")
                            let task = Process(); task.launchPath = "/usr/sbin/screencapture"; task.arguments = ["-i", tempUrl.path]
                            task.terminationHandler = { _ in
                                if FileManager.default.fileExists(atPath: tempUrl.path) {
                                    let openTask = Process(); openTask.launchPath = "/usr/bin/open"; openTask.arguments = ["-a", "Preview", tempUrl.path]; openTask.launch()
                                }
                            }; task.launch(); showMessage = "请画框截取..."
                        }),
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
                        ToolItem(icon: "pencil.and.outline", title: "图像编辑与裁剪", subtitle: "", action: {
                            let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = false
                            if #available(macOS 11.0, *) { panel.allowedContentTypes = [.image] }
                            if panel.runModal() == .OK, let url = panel.url {
                                let newUrl = SettingsManager.shared.saveUrl.appendingPathComponent("图片编辑_\(Int(Date().timeIntervalSince1970)).\(url.pathExtension)")
                                do {
                                    try FileManager.default.copyItem(at: url, to: newUrl)
                                    let task = Process(); task.launchPath = "/usr/bin/open"; task.arguments = ["-a", "Preview", newUrl.path]; task.launch()
                                    showMessage = "已创建副本，可进行编辑保存。"
                                } catch { showMessage = "创建副本失败" }
                            }
                        })
                    ])
                    
                    // 2. Media Engine
                    ToolboxSection(title: "🎬 多媒体引擎", tools: [
                        ToolItem(icon: DownloadManager.shared.isDownloading ? "arrow.down.circle.fill" : "arrow.down.circle", title: DownloadManager.shared.isDownloading ? "解析下载中..." : "全网媒体解析", subtitle: "", action: {
                            let alert = NSAlert(); alert.messageText = "媒体链接提取"; alert.informativeText = "请粘贴视频或媒体链接："; let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24)); alert.accessoryView = input; alert.addButton(withTitle: "极速下载"); alert.addButton(withTitle: "取消")
                            if alert.runModal() == .alertFirstButtonReturn {
                                DownloadManager.shared.downloadMedia(from: input.stringValue, saveTo: SettingsManager.shared.saveUrl) { success, msg in showMessage = msg }
                            }
                        }),
                        ToolItem(icon: ultimateManager.isProcessing ? "hourglass" : "film.circle.fill", title: ultimateManager.isProcessing ? "底层处理中..." : "终极视频工坊", subtitle: "", action: { showFFmpegDialog() })
                    ])
                    
                    // 3. Workflow
                    ToolboxSection(title: "📄 文档创作流", tools: [
                        ToolItem(icon: speechManager.isRecording ? "mic.fill" : "mic", title: speechManager.isRecording ? "正在倾听..." : "语音听写", subtitle: "", action: {
                            speechManager.toggleRecording(); if speechManager.isRecording { showMessage = "正在倾听中..." }
                        }),
                        ToolItem(icon: TranslateManager.shared.isTranslating ? "globe.americas" : "character.book.closed", title: TranslateManager.shared.isTranslating ? "..." : "多语言翻译", subtitle: "Option+3", action: {
                            TranslateManager.shared.translateClipboard { result in
                                if let res = result {
                                    FloatingWindowManager.shared.show(title: "翻译结果", text: res)
                                } else {
                                    showMessage = "请先复制或选中要翻译的文字"
                                }
                            }
                        }),
                        ToolItem(icon: ultimateManager.isProcessing ? "hourglass" : "doc.text.magnifyingglass", title: ultimateManager.isProcessing ? "转换中..." : "宇宙文档转换", subtitle: "", action: { showPandocDialog() }),
                        ToolItem(icon: DocumentManager.shared.isProcessing ? "doc.on.doc.fill" : "doc.on.doc", title: DocumentManager.shared.isProcessing ? "..." : "智能 PDF 拼接", subtitle: "", action: {
                            let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseFiles = true; panel.canChooseDirectories = false
                            if #available(macOS 11.0, *) { panel.allowedContentTypes = [.pdf] }
                            if panel.runModal() == .OK, panel.urls.count > 1 {
                                DocumentManager.shared.mergePDFs(urls: panel.urls, saveTo: SettingsManager.shared.saveUrl) { success in showMessage = success ? "PDF 合并成功！" : "合并失败" }
                            } else if panel.urls.count == 1 { showMessage = "请至少选择两个 PDF" }
                        })
                    ])
                    
                    // 4. Dev Tools
                    ToolboxSection(title: "🛠️ 开发者辅助", tools: [
                        ToolItem(icon: "eyedropper", title: "屏幕取色", subtitle: "", action: { manager.pickColor(); showMessage = "颜色已复制" }),
                        ToolItem(icon: manager.isAwake ? "sun.max.fill" : "moon.zzz", title: manager.isAwake ? "防休眠(已开启)" : "屏幕防休眠", subtitle: "", action: { manager.toggleAwake() }),
                        ToolItem(icon: "curlybraces", title: "JSON 格式化", subtitle: "", action: { showMessage = manager.formatJSON() ? "JSON 已格式化" : "非有效 JSON" })
                    ])
                }
                .padding(20)
            }
            
            if let msg = showMessage {
                Text(msg)
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showMessage = nil }
                    }
            }
        }
    }
    
    private func showPandocDialog() {
        let alert = NSAlert()
        alert.messageText = "Pandoc 宇宙文档转化"
        alert.informativeText = "请选择文档转换格式："
        alert.addButton(withTitle: "Markdown 转 Word")
        alert.addButton(withTitle: "Word 转 Markdown")
        alert.addButton(withTitle: "网页(HTML) 转 Markdown")
        alert.addButton(withTitle: "取消")
        
        var action: UltimateManager.PandocAction?
        switch alert.runModal() {
        case .alertFirstButtonReturn: action = .mdToWord
        case .alertSecondButtonReturn: action = .wordToMd
        case .alertThirdButtonReturn: action = .htmlToMd
        default: return
        }
        
        guard let selectedAction = action else { return }
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            ultimateManager.processDocument(url: url, action: selectedAction) { success, msg in
                showMessage = msg
            }
        }
    }
    
    private func showImageProcessorDialog() {
        let alert = NSAlert()
        alert.messageText = "图像处理 (Image Processing)"
        alert.informativeText = "请选择处理预设："
        alert.addButton(withTitle: "精准宫格切图")
        alert.addButton(withTitle: "智能证件照底色")
        alert.addButton(withTitle: "转为 HEIC")
        alert.addButton(withTitle: "转为 JPG")
        alert.addButton(withTitle: "缩放至 50%")
        alert.addButton(withTitle: "取消 (Cancel)")
        
        var action: ImageAction?
        switch alert.runModal() {
        case .alertFirstButtonReturn: 
            action = showGridSlicerConfig()
            if action == nil { return }
        case .alertSecondButtonReturn: action = .idPhotoMaker
        case .alertThirdButtonReturn: action = .convertFormat(.heic)
        case NSApplication.ModalResponse(rawValue: 1003): action = .convertFormat(.jpeg)
        case NSApplication.ModalResponse(rawValue: 1004): action = .resize(scale: 0.5)
        default: return
        }
        
        guard let selectedAction = action else { return }
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if #available(macOS 11.0, *) { panel.allowedContentTypes = [.image] }
        if panel.runModal() == .OK, !panel.urls.isEmpty {
            imageProcessor.processImages(urls: panel.urls, action: selectedAction, saveTo: SettingsManager.shared.saveUrl) { success in
                showMessage = success ? "Images processed successfully!" : "Image processing failed."
            }
        }
    }
    
    private func showFFmpegDialog() {
        let alert = NSAlert()
        alert.messageText = "FFmpeg 极限媒体处理"
        alert.informativeText = "请选择对视频执行的操作："
        alert.addButton(withTitle: "生成高质量 GIF")
        alert.addButton(withTitle: "H.264 无损高压缩")
        alert.addButton(withTitle: "无损提取音频 (MP3)")
        alert.addButton(withTitle: "提取每一帧 (JPG)")
        alert.addButton(withTitle: "万能转码为 MP4")
        alert.addButton(withTitle: "取消 (Cancel)")
        
        var action: UltimateManager.FFmpegAction?
        switch alert.runModal() {
        case .alertFirstButtonReturn: action = .toGIF
        case .alertSecondButtonReturn: action = .compress
        case .alertThirdButtonReturn: action = .extractAudio
        case NSApplication.ModalResponse(rawValue: 1003): action = .extractFrames
        case NSApplication.ModalResponse(rawValue: 1004): action = .transcodeToMP4
        default: return
        }
        
        guard let selectedAction = action else { return }
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if #available(macOS 11.0, *) { panel.allowedContentTypes = [.movie] }
        if panel.runModal() == .OK, let url = panel.url {
            ultimateManager.processVideo(url: url, action: selectedAction) { success, msg in
                showMessage = msg
            }
        }
    }
    
    private func showGridSlicerConfig() -> ImageAction? {
        let alert = NSAlert()
        alert.messageText = "精准宫格切图配置"
        alert.informativeText = "请选择预设或输入行列数："
        alert.addButton(withTitle: "确定 (OK)")
        alert.addButton(withTitle: "取消 (Cancel)")
        
        let customView = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 100))
        
        let presetLabel = NSTextField(labelWithString: "预设 (Presets):")
        presetLabel.frame = NSRect(x: 0, y: 70, width: 100, height: 20)
        presetLabel.isBordered = false
        presetLabel.drawsBackground = false
        
        let popupButton = NSPopUpButton(frame: NSRect(x: 100, y: 70, width: 140, height: 24))
        popupButton.addItems(withTitles: ["自定义 (Custom)", "2宫格横向 (1x2)", "2宫格纵向 (2x1)", "3宫格横向 (1x3)", "3宫格纵向 (3x1)", "4宫格 (2x2)", "6宫格 (2x3)", "9宫格 (3x3)", "25宫格 (5x5)", "32宫格 (4x8)"])
        popupButton.selectItem(at: 7) // Default to 9-grid
        
        let rowLabel = NSTextField(labelWithString: "行 (Rows):")
        rowLabel.frame = NSRect(x: 0, y: 30, width: 80, height: 20)
        rowLabel.isBordered = false
        rowLabel.drawsBackground = false
        let rowInput = NSTextField(string: "3")
        rowInput.frame = NSRect(x: 80, y: 30, width: 50, height: 20)
        
        let colLabel = NSTextField(labelWithString: "列 (Cols):")
        colLabel.frame = NSRect(x: 0, y: 0, width: 80, height: 20)
        colLabel.isBordered = false
        colLabel.drawsBackground = false
        let colInput = NSTextField(string: "3")
        colInput.frame = NSRect(x: 80, y: 0, width: 50, height: 20)
        
        customView.addSubview(presetLabel)
        customView.addSubview(popupButton)
        customView.addSubview(rowLabel)
        customView.addSubview(rowInput)
        customView.addSubview(colLabel)
        customView.addSubview(colInput)
        alert.accessoryView = customView
        
        if alert.runModal() == .alertFirstButtonReturn {
            let index = popupButton.indexOfSelectedItem
            var r = 1, c = 1
            switch index {
            case 1: r = 1; c = 2
            case 2: r = 2; c = 1
            case 3: r = 1; c = 3
            case 4: r = 3; c = 1
            case 5: r = 2; c = 2
            case 6: r = 2; c = 3
            case 7: r = 3; c = 3
            case 8: r = 5; c = 5
            case 9: r = 4; c = 8
            default: // Custom
                r = max(1, Int(rowInput.stringValue) ?? 1)
                c = max(1, Int(colInput.stringValue) ?? 1)
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
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(0..<tools.count, id: \.self) { index in
                    ToolRow(item: tools[index])
                    if index < tools.count - 1 {
                        Divider().padding(.leading, 42)
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
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
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .frame(width: 24, alignment: .center)
                
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { h in isHovered = h; if h { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() } }
    }
}
