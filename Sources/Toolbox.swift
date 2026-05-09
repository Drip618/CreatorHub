import SwiftUI
import UniformTypeIdentifiers

struct ToolItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let actionId: String
    let action: () -> Void
}

struct ToolboxView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var ultimateManager = UltimateManager.shared
    @ObservedObject var imageProcessor = ImageProcessor.shared
    @State private var showMessage: String? = nil
    
    // Config Sheet State
    @State private var activeConfigType: ConfigType? = nil
    @State private var selectedUrls: [URL] = []
    @State private var isConfigPresented: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 25) {
                    ToolboxSection(title: "🎬 创作流 (Creative Pro)", tools: [
                        ToolItem(icon: "camera.viewfinder", title: "屏幕截图", subtitle: "自动保存并拷贝至剪贴板", actionId: "screenshot", action: { triggerScreenshot(mode: .normal) }),
                        ToolItem(icon: "text.viewfinder", title: "文字识别", subtitle: "一键提取屏幕文字", actionId: "ocr", action: { triggerScreenshot(mode: .ocr) }),
                        ToolItem(icon: "character.book.closed", title: "图像翻译专家", subtitle: "截图翻译 或 选择本地图片", actionId: "translate", action: { showTranslateMenu() }),
                        ToolItem(icon: "waveform", title: "音频标准化", subtitle: "一键处理音量平衡 (-14 LUFS)", actionId: "normalize_audio", action: { normalizeAudioFlow() }),
                        ToolItem(icon: "arrow.triangle.2.circlepath.video", title: "万能视频转码", subtitle: "分辨率/格式/画质自由配置", actionId: "video_transcode", action: { pickFilesAsync(type: .videoTranscode) }),
                        ToolItem(icon: "video.slash", title: "视频去水印", subtitle: "智能修补，支持批量处理", actionId: "media_download", action: { showFFmpegDialogAsync() })
                    ])
                    
                    ToolboxSection(title: "🖼️ 影像工坊 (Image Lab)", tools: [
                        ToolItem(icon: "wand.and.stars", title: "万能图像处理", subtitle: "尺寸/格式/隐私/水印", actionId: "image_process", action: { pickFilesAsync(type: .imageProcess) }),
                        ToolItem(icon: "square.grid.3x3", title: "多视图切割", subtitle: "3/6/9/12/25/32 宫格", actionId: "grid_slice", action: { pickFilesAsync(type: .gridSlice) }),
                        ToolItem(icon: "person.crop.square", title: "证件照制作", subtitle: "智能抠图换底，多色可选", actionId: "id_photo", action: { pickFilesAsync(type: .idPhoto) }),
                        ToolItem(icon: "doc.on.doc", title: "全能文档合并", subtitle: "Word/PDF/MD 无损合并", actionId: "merge_docs", action: { mergeDocumentsAsync() })
                    ])
                    
                    ToolboxSection(title: "📄 极速工作流 (Workflow)", tools: [
                        ToolItem(icon: "doc.text.inverse", title: "XML 版本降级", subtitle: "适配 FCPX/PR 工程版本", actionId: "xml_downgrade", action: { downgradeXMLFlowAsync() }),
                        ToolItem(icon: "trash", title: "媒体缓存清理", subtitle: "释放 FCPX/PR 磁盘空间", actionId: "clean_cache", action: { cleanCacheFlowAsync() }),
                        ToolItem(icon: "character.cursor.ibeam", title: "宇宙文档转换", subtitle: "Word/PDF/MD 自由互转", actionId: "doc_convert", action: { showPandocDialogAsync() }),
                        ToolItem(icon: "ruler", title: "万能计算与换算", subtitle: "单位/汇率/科学计算", actionId: "unit_calc", action: { (NSApp.delegate as? AppDelegate)?.showSmartCalc(tab: 1) })
                    ])

                    ToolboxSection(title: "📊 智能辅助", tools: [
                        ToolItem(icon: "eyedropper", title: "屏幕取色", subtitle: "实时提取 HEX/RGB 代码", actionId: "pick_color", action: { settings.pickColor(); showMessage = "颜色已复制" }),
                        ToolItem(icon: settings.isAwake ? "sun.max.fill" : "moon.zzz", title: "屏幕常亮", subtitle: "阻止系统进入睡眠模式", actionId: "anti_sleep", action: { settings.toggleAwake() }),
                        ToolItem(icon: "curlybraces", title: "JSON 专家", subtitle: "格式化/美化/结构验证", actionId: "json_format", action: { showMessage = settings.smartJSONConvert() }),
                        ToolItem(icon: "bolt.fill", title: "快速开始", subtitle: "查看软件使用手册", actionId: "help", action: { showManual() })
                    ])
                }
                .padding(20)
            }
            
            if let msg = showMessage {
                Text(msg).font(.subheadline).foregroundColor(.green).padding()
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showMessage = nil } }
            }
        }
        .sheet(isPresented: $isConfigPresented) {
            if let type = activeConfigType {
                ToolConfigView(type: type, urls: selectedUrls, isPresented: $isConfigPresented) { config in
                    executeWithConfig(type: type, config: config)
                }
            }
        }
    }
    
    // MARK: - Async File Pickers
    private func pickFilesAsync(type: ConfigType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        if type == .videoTranscode {
            panel.allowedContentTypes = [.movie, .video]
        } else {
            panel.allowedContentTypes = [.image]
        }
        
        panel.begin { response in
            if response == .OK {
                DispatchQueue.main.async {
                    self.selectedUrls = panel.urls
                    self.activeConfigType = type
                    self.isConfigPresented = true
                }
            }
        }
    }
    
    private func showTranslateMenu() {
        let alert = NSAlert()
        alert.messageText = "图像翻译"
        alert.informativeText = "请选择翻译方式："
        alert.addButton(withTitle: "屏幕截图翻译")
        alert.addButton(withTitle: "选择本地图片")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            triggerScreenshot(mode: .translate)
        } else if response == .alertSecondButtonReturn {
            translateImageAsync()
        }
    }
    
    private func translateImageAsync() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    // We need a helper to recognize text from a specific URL
                    OCRManager.shared.recognizeTextFromURL(url) { text in
                        if let t = text {
                            TranslateManager.shared.translateText(t) { result in
                                FloatingWindowManager.shared.show(title: "图片翻译结果", text: result ?? "翻译失败")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func triggerScreenshot(mode: AppDelegate.ScreenshotMode) { (NSApp.delegate as? AppDelegate)?.triggerScreenshot(mode: mode) }
    
    private func executeWithConfig(type: ConfigType, config: Any) {
        switch type {
        case .imageProcess:
            if let (scale, format) = config as? (Double, UTType) {
                imageProcessor.processImages(urls: selectedUrls, action: .resize(scale: scale), saveTo: settings.saveUrl) { _ in showMessage = "图片处理完成" }
            }
        case .videoTranscode:
            if let (res, format, quality) = config as? (String, String, String) {
                for url in selectedUrls {
                    ultimateManager.processVideo(url: url, action: .customTranscode(res: res, format: format, quality: quality)) { _, m in showMessage = m }
                }
            }
        case .idPhoto:
            if let color = config as? Color {
                let nsColor = NSColor(color)
                if let ciColor = CIColor(color: nsColor) {
                    imageProcessor.processImages(urls: selectedUrls, action: .idPhotoMaker(color: ciColor), saveTo: settings.saveUrl) { _ in showMessage = "证件照制作完成" }
                }
            }
        case .gridSlice:
            if let (r, c) = config as? (Int, Int) {
                imageProcessor.processImages(urls: selectedUrls, action: .sliceGrid(rows: r, columns: c), saveTo: settings.saveUrl) { _ in showMessage = "多视图切割完成" }
            }
        }
    }
    
    private func showFFmpegDialogAsync() {
        let panel = NSOpenPanel()
        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    ultimateManager.processVideo(url: url, action: .compress) { s, m in showMessage = m }
                }
            }
        }
    }
    
    private func showPandocDialogAsync() {
        let panel = NSOpenPanel()
        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    ultimateManager.processDocument(url: url, action: .mdToWord) { s, m in showMessage = m }
                }
            }
        }
    }
    
    private func cleanCacheFlowAsync() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.begin { response in
            if response == .OK {
                DispatchQueue.main.async {
                    ultimateManager.cleanFCPXCache(urls: panel.urls) { bytes in showMessage = "已清理 \(bytes / 1024 / 1024)MB 缓存文件" }
                }
            }
        }
    }
    
    private func normalizeAudioFlow() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .movie].compactMap { $0 }
        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    ultimateManager.normalizeLoudness(url: url) { s, m in showMessage = m }
                }
            }
        }
    }
    
    private func mergeDocumentsAsync() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.begin { response in
            if response == .OK {
                DispatchQueue.main.async {
                    DocumentManager.shared.mergeFiles(urls: panel.urls) { success, msg in showMessage = msg }
                }
            }
        }
    }
    
    private func downgradeXMLFlowAsync() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml, .init(filenameExtension: "fcpxml")!].compactMap { $0 }
        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    ultimateManager.isProcessing = true
                    DocumentManager.shared.downgradeXML(url: url, targetVersion: "1.9") { success, msg in
                        ultimateManager.isProcessing = false
                        showMessage = msg
                    }
                }
            }
        }
    }

    private func showManual() {
        if let manualUrl = Bundle.main.url(forResource: "Creator_Hub_User_Manual", withExtension: "md") {
            NSWorkspace.shared.open(manualUrl)
        } else {
            // Fallback to project root if building from source
            let path = "/Users/Drip/Antigravity/Projects/MacCaptureHubNative/Creator_Hub_User_Manual.md"
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
}

struct ToolboxSection: View {
    let title: String; let tools: [ToolItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.secondary).padding(.leading, 5)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(tools) { ToolRow(tool: $0) }
            }
        }
    }
}

struct ToolRow: View {
    let tool: ToolItem
    @State private var isHovered = false
    var body: some View {
        Button(action: tool.action) {
            HStack(spacing: 12) {
                Image(systemName: tool.icon).font(.system(size: 20)).foregroundColor(.accentColor).frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.title).font(.system(size: 13, weight: .semibold))
                    Text(tool.subtitle).font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                if let hkString = SettingsManager.shared.getHotkeyString(for: tool.actionId) {
                    Text(hkString).font(.system(size: 10, weight: .bold, design: .monospaced)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.accentColor.opacity(0.1)).foregroundColor(.accentColor).cornerRadius(4).padding(.trailing, 4)
                }
            }
            .padding(12).background(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.8 : 0.4)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor.opacity(isHovered ? 0.3 : 0), lineWidth: 1))
        }
        .buttonStyle(.plain).onHover { isHovered = $0 }
    }
}
