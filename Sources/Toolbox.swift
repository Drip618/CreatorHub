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
                        ToolItem(icon: "camera.viewfinder", title: "屏幕截图", subtitle: "自动保存并拷贝至剪贴板", actionId: "screenshot", action: { triggerScreenshot() }),
                        ToolItem(icon: "text.viewfinder", title: "文字识别", subtitle: "一键提取屏幕文字", actionId: "ocr", action: { triggerScreenshot() }),
                        ToolItem(icon: "character.book.closed", title: "多语言翻译", subtitle: "瞬时文档/网页翻译", actionId: "translate", action: { triggerScreenshot() }),
                        ToolItem(icon: "waveform", title: "音频标准化", subtitle: "一键处理音量平衡 (-14 LUFS)", actionId: "normalize_audio", action: { normalizeAudioFlow() }),
                        ToolItem(icon: "arrow.triangle.2.circlepath.video", title: "万能视频转码", subtitle: "自定义分辨率/格式/画质", actionId: "video_transcode", action: { pickFiles(type: .videoTranscode) }),
                        ToolItem(icon: "video.slash", title: "高清视频去水印", subtitle: "智能补全，不留痕迹", actionId: "media_download", action: { showFFmpegDialog() })
                    ])
                    
                    ToolboxSection(title: "🖼️ 影像工坊 (Image Lab)", tools: [
                        ToolItem(icon: "photo.on.rectangle", title: "万能图像处理", subtitle: "批量转换尺寸与格式", actionId: "image_process", action: { pickFiles(type: .imageProcess) }),
                        ToolItem(icon: "person.crop.square", title: "证件照智能换底", subtitle: "自动抠图，自由选色", actionId: "id_photo", action: { pickFiles(type: .idPhoto) }),
                        ToolItem(icon: "square.grid.3x3", title: "九宫格裁剪", subtitle: "一键生成朋友圈/封面图", actionId: "grid_slice", action: { pickFiles(type: .gridSlice) }),
                        ToolItem(icon: "shield.checkerboard", title: "隐私净化", subtitle: "一键清除 EXIF/GPS 信息", actionId: "clean_exif", action: { pickFiles(type: .imageProcess) })
                    ])
                    
                    ToolboxSection(title: "📄 极速工作流 (Workflow)", tools: [
                        ToolItem(icon: "doc.text.inverse", title: "XML 版本降级", subtitle: "适配 FCPX/PR 低版本工程", actionId: "xml_downgrade", action: { downgradeXMLFlow() }),
                        ToolItem(icon: "doc.on.doc", title: "全能文档合并", subtitle: "Word/PDF/MD 无损合并", actionId: "merge_docs", action: { mergeDocuments() }),
                        ToolItem(icon: "trash", title: "库缓存清理", subtitle: "释放磁盘 FCPX/PR 缓存", actionId: "clean_cache", action: { cleanCacheFlow() }),
                        ToolItem(icon: "character.cursor.ibeam", title: "宇宙文档转换", subtitle: "Word/PDF/MD 自由互转", actionId: "doc_convert", action: { showPandocDialog() })
                    ])

                    ToolboxSection(title: "📊 智能生产力", tools: [
                        ToolItem(icon: "eyedropper", title: "屏幕取色", subtitle: "获取 UI 颜色码", actionId: "pick_color", action: { settings.pickColor(); showMessage = "颜色已复制" }),
                        ToolItem(icon: settings.isAwake ? "sun.max.fill" : "moon.zzz", title: settings.isAwake ? "已开启" : "屏幕防休眠", subtitle: "阻止系统自动锁屏", actionId: "anti_sleep", action: { settings.toggleAwake() }),
                        ToolItem(icon: "ruler", title: "万能单位换算", subtitle: "国际单位瞬时转换", actionId: "unit_calc", action: { (NSApp.delegate as? AppDelegate)?.showSmartCalc(tab: 1) }),
                        ToolItem(icon: "dollarsign.circle", title: "全球实时汇率", subtitle: "主流货币实时换算", actionId: "currency_calc", action: { (NSApp.delegate as? AppDelegate)?.showSmartCalc(tab: 2) }),
                        ToolItem(icon: "curlybraces", title: "JSON 专家工具", subtitle: "文本转 JSON / 美化", actionId: "json_format", action: { showMessage = settings.smartJSONConvert() }),
                        ToolItem(icon: "plus.forwardslash.minus", title: "万能计算与换算", subtitle: "科学计算引擎", actionId: "science_calc", action: { (NSApp.delegate as? AppDelegate)?.showSmartCalc(tab: 0) })
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
    
    // Actions
    private func triggerScreenshot() { (NSApp.delegate as? AppDelegate)?.triggerScreenshot() }
    
    private func pickFiles(type: ConfigType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        if type == .videoTranscode {
            panel.allowedContentTypes = [.movie, .video]
        } else {
            panel.allowedContentTypes = [.image]
        }
        
        if panel.runModal() == .OK {
            self.selectedUrls = panel.urls
            self.activeConfigType = type
            self.isConfigPresented = true
        }
    }
    
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
                imageProcessor.processImages(urls: selectedUrls, action: .sliceGrid(rows: r, columns: c), saveTo: settings.saveUrl) { _ in showMessage = "九宫格裁剪完成" }
            }
        }
    }
    
    private func showFFmpegDialog() { let panel = NSOpenPanel(); if panel.runModal() == .OK, let url = panel.url { ultimateManager.processVideo(url: url, action: .compress) { s, m in showMessage = m } } }
    private func showPandocDialog() { let panel = NSOpenPanel(); if panel.runModal() == .OK, let url = panel.url { ultimateManager.processDocument(url: url, action: .mdToWord) { s, m in showMessage = m } } }
    private func cleanCacheFlow() { let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; if panel.runModal() == .OK { ultimateManager.cleanFCPXCache(urls: panel.urls) { bytes in showMessage = "已清理 \(bytes / 1024 / 1024)MB 缓存文件" } } }
    private func normalizeAudioFlow() { let panel = NSOpenPanel(); panel.allowedContentTypes = [.audio, .movie].compactMap { $0 }; if panel.runModal() == .OK, let url = panel.url { ultimateManager.normalizeLoudness(url: url) { s, m in showMessage = m } } }
    private func mergeDocuments() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseFiles = true; if panel.runModal() == .OK { DocumentManager.shared.mergeFiles(urls: panel.urls) { success, msg in showMessage = msg } } }
    private func downgradeXMLFlow() { let panel = NSOpenPanel(); panel.allowedContentTypes = [.xml, .init(filenameExtension: "fcpxml")!].compactMap { $0 }; if panel.runModal() == .OK, let url = panel.url { ultimateManager.isProcessing = true; DocumentManager.shared.downgradeXML(url: url, targetVersion: "1.9") { success, msg in ultimateManager.isProcessing = false; showMessage = msg } } }
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
