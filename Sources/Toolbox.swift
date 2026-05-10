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
    @ObservedObject var docManager = DocumentManager.shared
    @State private var showMessage: String? = nil
    
    // Config Sheet State
    @State private var activeConfigType: ConfigType? = nil
    @State private var selectedUrls: [URL] = []
    @State private var isConfigPresented: Bool = false
    
    private var isAnyProcessing: Bool {
        imageProcessor.isProcessing || ultimateManager.isProcessing || docManager.isProcessing
    }
    
    private var currentProgress: Double {
        if imageProcessor.isProcessing { return imageProcessor.progress }
        if ultimateManager.isProcessing { return ultimateManager.progress }
        return 0.0
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 25) {
                    ToolboxSection(title: "🎬 创作流 (Creative Pro)", tools: [
                        ToolItem(icon: "camera.viewfinder", title: "屏幕截图", subtitle: "自动保存并拷贝至剪贴板", actionId: "screenshot", action: { triggerScreenshot(mode: .normal) }),
                        ToolItem(icon: "text.magnifyingglass", title: "划词翻译", subtitle: "选中文字后一键翻译", actionId: "translate_selection", action: { (NSApp.delegate as? AppDelegate)?.translateSelectedText() }),
                        ToolItem(icon: "text.viewfinder", title: "文字识别", subtitle: "一键提取屏幕文字", actionId: "ocr", action: { triggerScreenshot(mode: .ocr) }),
                        ToolItem(icon: "character.book.closed", title: "图片翻译", subtitle: "截图 或 选择本地文件", actionId: "translate", action: { 
                            self.activeConfigType = .translation
                            self.isConfigPresented = true
                        }),
                        ToolItem(icon: "waveform", title: "音频标准化", subtitle: "一键平衡音量 (-14 LUFS)", actionId: "normalize_audio", action: { normalizeAudioFlow() }),
                        ToolItem(icon: "video.fill", title: "万能视频转码", subtitle: "分辨率/格式/画质配置", actionId: "video_transcode", action: { pickFilesAsync(type: .videoTranscode) })
                    ])
                    
                    ToolboxSection(title: "🖼️ 影像工坊 (Image Lab)", tools: [
                        ToolItem(icon: "wand.and.stars", title: "万能图像处理", subtitle: "尺寸/格式/隐私/水印", actionId: "image_process", action: { pickFilesAsync(type: .imageProcess) }),
                        ToolItem(icon: "square.grid.3x3", title: "多视图切割", subtitle: "3/6/9/12/25/32 宫格", actionId: "grid_slice", action: { pickFilesAsync(type: .gridSlice) }),
                        ToolItem(icon: "person.crop.square", title: "证件照制作", subtitle: "智能抠图，自定义换底", actionId: "id_photo", action: { pickFilesAsync(type: .idPhoto) }),
                        ToolItem(icon: "doc.on.doc", title: "全能文档合并", subtitle: "Word/PDF/MD 无损合并", actionId: "merge_docs", action: { mergeDocumentsAsync() })
                    ])
                    
                    ToolboxSection(title: "📄 极速工作流 (Workflow)", tools: [
                        ToolItem(icon: "doc.text.fill", title: "XML 版本降级", subtitle: "适配 FCPX/PR 低版本", actionId: "xml_downgrade", action: { downgradeXMLFlowAsync() }),
                        ToolItem(icon: "trash", title: "媒体缓存清理", subtitle: "释放 FCPX/PR 磁盘缓存", actionId: "clean_cache", action: { cleanCacheFlowAsync() }),
                        ToolItem(icon: "character.cursor.ibeam", title: "宇宙文档转换", subtitle: "Word/PDF/MD 自由互转", actionId: "doc_convert", action: { showPandocDialogAsync() }),
                        ToolItem(icon: "plus.slash.minus", title: "万能计算与换算", subtitle: "单位/汇率/科学计算", actionId: "unit_calc", action: { (NSApp.delegate as? AppDelegate)?.showSmartCalc(tab: 1) })
                    ])
                }
                .padding(20)
            }
            .disabled(isAnyProcessing)
            
            // Modern Processing Overlay
            if isAnyProcessing {
                ZStack {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        ProgressView(value: currentProgress) {
                            Text("正在处理中...").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        } currentValueLabel: {
                            Text("\(Int(currentProgress * 100))%").font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        }
                        .progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.5)
                        Text("请稍候，任务正在后台执行").font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                        
                        Button(action: { 
                            imageProcessor.isProcessing = false
                            ultimateManager.isProcessing = false
                            docManager.isProcessing = false
                        }) {
                            Text("强制取消").font(.system(size: 11)).foregroundColor(.white.opacity(0.5)).padding(.top, 10)
                        }.buttonStyle(.plain)
                    }
                    .padding(30).background(Color(NSColor.windowBackgroundColor).opacity(0.95)).cornerRadius(20).shadow(radius: 10)
                }
                .transition(.opacity)
            }
            
            if let msg = showMessage {
                VStack {
                    Spacer()
                    Text(msg).font(.subheadline).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Color.black.opacity(0.8)).cornerRadius(20).padding(.bottom, 40)
                }
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
    
    // MARK: - Handlers
    private func pickFilesAsync(type: ConfigType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = (type == .videoTranscode) ? [.movie, .video] : [.image]
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
    
    private func triggerScreenshot(mode: AppDelegate.ScreenshotMode) { (NSApp.delegate as? AppDelegate)?.triggerScreenshot(mode: mode) }
    
    private func executeWithConfig(type: ConfigType, config: Any) {
        switch type {
        case .imageProcess:
            if let (scale, format) = config as? (Double, UTType) {
                imageProcessor.processImages(urls: selectedUrls, action: .resize(scale: scale), saveTo: settings.saveUrl) { _ in showMessage = "处理完成" }
            }
        case .videoTranscode:
            if let (res, format, quality) = config as? (String, String, String) {
                for url in selectedUrls { ultimateManager.processVideo(url: url, action: .customTranscode(res: res, format: format, quality: quality)) { _, m in showMessage = m } }
            }
        case .idPhoto:
            if let color = config as? Color {
                let nsColor = NSColor(color)
                if let ciColor = CIColor(color: nsColor) {
                    imageProcessor.processImages(urls: selectedUrls, action: .idPhotoMaker(color: ciColor), saveTo: settings.saveUrl) { _ in showMessage = "制作完成" }
                }
            }
        case .gridSlice:
            if let (r, c) = config as? (Int, Int) {
                imageProcessor.processImages(urls: selectedUrls, action: .sliceGrid(rows: r, columns: c), saveTo: settings.saveUrl) { _ in showMessage = "切割完成" }
            }
        case .translation:
            if let mode = config as? String {
                if mode == "screen" { triggerScreenshot(mode: .translate) }
                else { TranslateManager.shared.pickImageAndTranslate() }
            }
        }
    }
    
    private func showFFmpegDialogAsync() {
        let panel = NSOpenPanel(); panel.begin { response in if response == .OK, let url = panel.url { ultimateManager.processVideo(url: url, action: .compress) { _, m in showMessage = m } } }
    }
    private func showPandocDialogAsync() {
        let panel = NSOpenPanel(); panel.begin { response in if response == .OK, let url = panel.url { ultimateManager.processDocument(url: url, action: .mdToWord) { _, m in showMessage = m } } }
    }
    private func cleanCacheFlowAsync() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false
        panel.begin { response in if response == .OK { ultimateManager.cleanFCPXCache(urls: panel.urls) { b in showMessage = "已清理 \(b/1024/1024)MB" } } }
    }
    private func normalizeAudioFlow() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.audio, .movie].compactMap { $0 }
        panel.begin { response in if response == .OK, let url = panel.url { ultimateManager.normalizeLoudness(url: url) { _, m in showMessage = m } } }
    }
    private func mergeDocumentsAsync() {
        let panel = NSOpenPanel(); panel.allowsMultipleSelection = true
        panel.begin { response in if response == .OK { DocumentManager.shared.mergeFiles(urls: panel.urls) { _, m in showMessage = m } } }
    }
    private func downgradeXMLFlowAsync() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.xml, .init(filenameExtension: "fcpxml")!].compactMap { $0 }
        panel.begin { response in if response == .OK, let url = panel.url { DocumentManager.shared.downgradeXML(url: url, targetVersion: "1.9") { _, m in showMessage = m } } }
    }
}

struct ToolboxSection: View {
    let title: String; let tools: [ToolItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.secondary).padding(.leading, 5)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) { ForEach(tools) { ToolRow(tool: $0) } }
        }
    }
}

struct ToolRow: View {
    let tool: ToolItem; @State private var isHovered = false
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
                    Text(hkString).font(.system(size: 10, weight: .bold, design: .monospaced)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.accentColor.opacity(0.1)).foregroundColor(.accentColor).cornerRadius(4)
                }
            }
            .padding(12).background(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.8 : 0.4)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor.opacity(isHovered ? 0.3 : 0), lineWidth: 1))
        }
        .buttonStyle(.plain).onHover { isHovered = $0 }
    }
}
