import SwiftUI

struct ToolItem {
    let icon: String
    let title: String
    let subtitle: String
    let actionId: String
    let action: () -> Void
}

struct ToolboxView: View {
    @ObservedObject var lang = LanguageManager.shared
    @ObservedObject var speechManager = SpeechManager.shared
    @ObservedObject var ocrManager = OCRManager.shared
    @ObservedObject var imageProcessor = ImageProcessor.shared
    @ObservedObject var ultimateManager = UltimateManager.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var showMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    ToolboxSection(title: "🖥️ 屏幕与图像", tools: [
                        ToolItem(icon: "macwindow.badge.plus", title: "屏幕截图", subtitle: "全屏捕捉", actionId: "screenshot", action: { triggerScreenshot() }),
                        ToolItem(icon: "text.viewfinder", title: ocrManager.isRecognizing ? "识别中..." : "文字识别", subtitle: "提取文本", actionId: "ocr", action: {
                            ocrManager.recognizeTextFromScreen { result in showMessage = result != nil ? "识别完成" : "识别失败" }
                        }),
                        ToolItem(icon: "lock.shield", title: "图片隐私净化", subtitle: "清除 EXIF 隐私数据", actionId: "image_privacy", action: {
                            let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseFiles = true
                            if #available(macOS 11.0, *) { panel.allowedContentTypes = [.image] }
                            if panel.runModal() == .OK, !panel.urls.isEmpty {
                                ultimateManager.stripEXIF(from: panel.urls) { count in showMessage = "成功净化 \(count) 张图片！" }
                            }
                        }),
                        ToolItem(icon: imageProcessor.isProcessing ? "hourglass" : "photo.stack", title: imageProcessor.isProcessing ? "正在处理..." : "万能图像处理", subtitle: "批量转换尺寸/格式", actionId: "image_process", action: { showImageProcessorDialog() }),
                        ToolItem(icon: "pencil.and.outline", title: "图像编辑与裁剪", subtitle: "快速标记与修图", actionId: "image_edit", action: { openPreviewEdit() })
                    ])
                    
                    ToolboxSection(title: "🎬 多媒体引擎", tools: [
                        ToolItem(icon: ultimateManager.isProcessing ? "hourglass" : "film.circle.fill", title: ultimateManager.isProcessing ? "处理中..." : "终极视频工坊", subtitle: "转码、抽帧、去水印", actionId: "ffmpeg_process", action: { showFFmpegDialog() }),
                        ToolItem(icon: DownloadManager.shared.isDownloading ? "arrow.down.circle.fill" : "arrow.down.circle", title: DownloadManager.shared.isDownloading ? "解析中..." : "全网媒体解析", subtitle: "解析并下载素材", actionId: "media_download", action: { showDownloadDialog() })
                    ])
                    
                    ToolboxSection(title: "📄 文档创作流", tools: [
                        ToolItem(icon: speechManager.isRecording ? "mic.fill" : "mic", title: speechManager.isRecording ? "正在听写..." : "语音听写", subtitle: "实时语音转文字", actionId: "speech_to_text", action: {
                            speechManager.toggleRecording(); if speechManager.isRecording { showMessage = "正在倾听..." }
                        }),
                        ToolItem(icon: TranslateManager.shared.isTranslating ? "globe" : "character.book.closed", title: TranslateManager.shared.isTranslating ? "正在翻译..." : "多语言翻译", subtitle: "瞬时互译", actionId: "translate", action: {
                            (NSApp.delegate as? AppDelegate)?.translateSelectedText()
                        }),
                        ToolItem(icon: ultimateManager.isProcessing ? "hourglass" : "doc.text.magnifyingglass", title: ultimateManager.isProcessing ? "转换中..." : "宇宙文档转换", subtitle: "Word/MD 格式互转", actionId: "doc_convert", action: { showPandocDialog() }),
                        ToolItem(icon: DocumentManager.shared.isProcessing ? "doc.on.doc.fill" : "doc.on.doc", title: DocumentManager.shared.isProcessing ? "合并中..." : "全能文档/表格合并", subtitle: "批量合并文件数据", actionId: "merge_docs", action: { mergeDocuments() })
                    ])
                    
                    ToolboxSection(title: "🎬 创作增强 (Pro Workflow)", tools: [
                        ToolItem(icon: "doc.on.doc.fill", title: "XML 版本降级", subtitle: "兼容旧版 FCPX/PR", actionId: "xml_downgrade", action: { downgradeXMLFlow() }),
                        ToolItem(icon: "folder.badge.minus", title: "库缓存智能清理", subtitle: "清理渲染/代理文件", actionId: "clean_cache", action: { cleanCacheFlow() }),
                        ToolItem(icon: "waveform.circle.fill", title: "音频音量标准化", subtitle: "自动平衡 -14 LUFS", actionId: "normalize_audio", action: { normalizeAudioFlow() })
                    ])
                    
                    ToolboxSection(title: "🔄 万能转换 (Media Pro)", tools: [
                        ToolItem(icon: "bolt.fill", title: "极速批量转换", subtitle: "ProRes 级转码体验", actionId: "batch_transcode", action: { showFFmpegDialog() }),
                        ToolItem(icon: "music.note.list", title: "无损音频提取", subtitle: "从视频提取原声", actionId: "audio_extract", action: { showFFmpegDialog() })
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
    }
    
    // Actions (rest omitted for brevity, but I'll include the necessary parts)
    private func triggerScreenshot() { (NSApp.delegate as? AppDelegate)?.triggerScreenshot() }
    private func openPreviewEdit() { let panel = NSOpenPanel(); if panel.runModal() == .OK, let url = panel.url { NSWorkspace.shared.open(url) } }
    private func showFFmpegDialog() { let panel = NSOpenPanel(); if panel.runModal() == .OK, let url = panel.url { ultimateManager.processVideo(url: url, action: .compress) { s, m in showMessage = m } } }
    private func showDownloadDialog() { showMessage = "请在剪贴板粘贴视频链接" }
    private func showPandocDialog() { let panel = NSOpenPanel(); if panel.runModal() == .OK, let url = panel.url { ultimateManager.processDocument(url: url, action: .mdToWord) { s, m in showMessage = m } } }
    private func showImageProcessorDialog() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; if panel.runModal() == .OK { imageProcessor.processImages(urls: panel.urls, action: .resize(scale: 0.5), saveTo: settings.saveUrl) { _ in showMessage = "图片处理完成" } } }
    private func cleanCacheFlow() { let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; if panel.runModal() == .OK { ultimateManager.cleanFCPXCache(urls: panel.urls) { bytes in showMessage = "已清理 \(bytes / 1024 / 1024)MB 缓存文件" } } }
    private func normalizeAudioFlow() { let panel = NSOpenPanel(); panel.allowedContentTypes = [.audio, .movie].compactMap { $0 }; if panel.runModal() == .OK, let url = panel.url { ultimateManager.normalizeLoudness(url: url) { s, m in showMessage = m } } }
    private func mergeDocuments() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseFiles = true; if panel.runModal() == .OK { DocumentManager.shared.mergeFiles(urls: panel.urls) { success, msg in showMessage = msg } } }
    private func downgradeXMLFlow() { let panel = NSOpenPanel(); panel.allowedContentTypes = [.xml, .init(filenameExtension: "fcpxml")!].compactMap { $0 }; if panel.runModal() == .OK, let url = panel.url { ultimateManager.isProcessing = true; DocumentManager.shared.downgradeXML(url: url, targetVersion: "1.9") { success, msg in ultimateManager.isProcessing = false; showMessage = msg } } }
}

struct ToolboxSection: View {
    let title: String; let tools: [ToolItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundColor(.secondary).padding(.leading, 8)
            VStack(spacing: 0) {
                ForEach(tools.indices, id: \.self) { i in
                    ToolRow(item: tools[i])
                    if i < tools.count - 1 { Divider().padding(.leading, 48) }
                }
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
    }
}

struct ToolRow: View {
    let item: ToolItem; @ObservedObject var settings = SettingsManager.shared; @State private var isHovered = false
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon).font(.system(size: 18)).foregroundColor(.accentColor).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.system(size: 14, weight: .medium))
                    if !item.subtitle.isEmpty { Text(item.subtitle).font(.system(size: 10)).foregroundColor(.secondary) }
                }
                Spacer()
                if let hkString = settings.getHotkeyString(for: item.actionId) {
                    Text(hkString).font(.system(size: 10, weight: .bold, design: .monospaced)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.accentColor.opacity(0.1)).foregroundColor(.accentColor).cornerRadius(4).padding(.trailing, 4)
                }
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain).onHover { isHovered = $0 }
    }
}
