import SwiftUI
import UniformTypeIdentifiers

enum ConfigType: Equatable {
    case imageProcess
    case videoTranscode
    case idPhoto
    case gridSlice
    case translation
}

// Grid preset templates
struct GridPreset: Identifiable, Equatable {
    let id: String
    let label: String
    let rows: Int
    let cols: Int
    var icon: String {
        switch id {
        case "1x3": return "rectangle.split.3x1"
        case "2x3": return "rectangle.split.3x1"
        case "3x3": return "square.grid.3x3"
        case "3x4": return "rectangle.split.3x1"
        case "5x5": return "square.grid.3x3"
        case "4x8": return "square.grid.3x3"
        default: return "square.grid.3x3"
        }
    }
}

struct ToolConfigView: View {
    let type: ConfigType
    let urls: [URL]
    @Binding var isPresented: Bool
    var onConfirm: (Any) -> Void

    // Image Config
    @State private var imageScale: Double = 0.5
    @State private var imageFormat: UTType = .jpeg

    // Video Config
    @State private var videoRes: String = "original"
    @State private var videoFormat: String = "mp4"
    @State private var videoQuality: String = "medium"

    // ID Photo
    @State private var bgColor: Color = Color(red: 0.26, green: 0.55, blue: 0.90)

    // Grid Slice
    let presets: [GridPreset] = [
        GridPreset(id: "1x3", label: "三视图 (1×3)", rows: 1, cols: 3),
        GridPreset(id: "2x3", label: "六视图 (2×3)", rows: 2, cols: 3),
        GridPreset(id: "3x3", label: "九宫格 (3×3)", rows: 3, cols: 3),
        GridPreset(id: "3x4", label: "十二视图 (3×4)", rows: 3, cols: 4),
        GridPreset(id: "5x5", label: "二十五视图 (5×5)", rows: 5, cols: 5),
        GridPreset(id: "4x8", label: "三十二视图 (4×8)", rows: 4, cols: 8),
        GridPreset(id: "custom", label: "自定义", rows: 3, cols: 3),
    ]
    @State private var selectedPreset: GridPreset? = nil
    @State private var customRows: Int = 3
    @State private var customCols: Int = 3

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText).font(.system(size: 16, weight: .bold))
                    if type != .translation {
                        Text("\(urls.count) 个文件已选择").font(.caption).foregroundColor(.secondary)
                    } else {
                        Text("请选择翻译来源").font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    switch type {
                    case .imageProcess: imageSection
                    case .videoTranscode: videoSection
                    case .idPhoto: idPhotoSection
                    case .gridSlice: gridSection
                    case .translation: translationSection
                    }
                }
                .padding(24)
            }

            if type != .translation {
                Divider()

                // Footer
                Button(action: handleConfirm) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("开始处理")
                        Spacer()
                        Text("\(urls.count) 个文件").foregroundColor(.white.opacity(0.7))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 20)
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 420)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .onAppear { selectedPreset = presets[2] } // Default to 3x3
    }

    // MARK: - Image Section
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            ConfigRow(title: "缩放比例") {
                HStack(spacing: 10) {
                    ForEach([("原图", 1.0), ("75%", 0.75), ("50%", 0.5), ("25%", 0.25)], id: \.0) { label, val in
                        Button(action: { imageScale = val }) {
                            Text(label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(imageScale == val ? .white : .primary)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(imageScale == val ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            ConfigRow(title: "输出格式") {
                HStack(spacing: 10) {
                    ForEach([("JPEG", UTType.jpeg), ("PNG", UTType.png), ("HEIC", UTType.heic)], id: \.0) { label, fmt in
                        Button(action: { imageFormat = fmt }) {
                            Text(label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(imageFormat == fmt ? .white : .primary)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(imageFormat == fmt ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Grid Section
    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            ConfigRow(title: "选择分割模式") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(presets) { preset in
                        Button(action: { selectedPreset = preset }) {
                            HStack {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 13))
                                    .frame(width: 20)
                                Text(preset.label)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                            }
                            .foregroundColor(selectedPreset?.id == preset.id ? .white : .primary)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(selectedPreset?.id == preset.id ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            if selectedPreset?.id == "custom" {
                HStack(spacing: 24) {
                    ConfigRow(title: "行数") {
                        Stepper("\(customRows) 行", value: $customRows, in: 1...20)
                    }
                    ConfigRow(title: "列数") {
                        Stepper("\(customCols) 列", value: $customCols, in: 1...20)
                    }
                }
                .transition(.opacity)
            }

            if let p = selectedPreset, p.id != "custom" {
                Text("将图片分割为 \(p.rows) 行 × \(p.cols) 列 = \(p.rows * p.cols) 张切片")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Video Section
    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            ConfigRow(title: "目标分辨率") {
                Picker("", selection: $videoRes) {
                    Text("保持原始分辨率").tag("original")
                    Text("4K   3840×2160").tag("2160p")
                    Text("2K   2560×1440").tag("1440p")
                    Text("1080p  1920×1080").tag("1080p")
                    Text("720p   1280×720").tag("720p")
                    Text("480p   720×480").tag("480p")
                }
                .pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
            }
            ConfigRow(title: "输出格式") {
                HStack(spacing: 8) {
                    ForEach([("MP4", "mp4"), ("MOV", "mov"), ("GIF", "gif"), ("WebM", "webm")], id: \.0) { label, fmt in
                        Button(action: { videoFormat = fmt }) {
                            Text(label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(videoFormat == fmt ? .white : .primary)
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .background(videoFormat == fmt ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
            ConfigRow(title: "编码预设") {
                HStack(spacing: 8) {
                    ForEach([("高画质", "veryslow"), ("均衡", "medium"), ("极速", "ultrafast")], id: \.0) { label, q in
                        Button(action: { videoQuality = q }) {
                            Text(label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(videoQuality == q ? .white : .primary)
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .background(videoQuality == q ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - ID Photo Section
    private var idPhotoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConfigRow(title: "证件照背景色") {
                HStack(spacing: 12) {
                    ForEach([
                        ("标准蓝", Color(red: 0.26, green: 0.55, blue: 0.90)),
                        ("标准红", Color(red: 0.85, green: 0.18, blue: 0.18)),
                        ("纯白", Color.white)
                    ], id: \.0) { name, c in
                        Button(action: { bgColor = c }) {
                            VStack(spacing: 4) {
                                Circle().fill(c)
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.accentColor, lineWidth: bgColor == c ? 2.5 : 0))
                                    .shadow(radius: bgColor == c ? 4 : 1)
                                Text(name).font(.system(size: 10)).foregroundColor(.secondary)
                            }
                        }.buttonStyle(PlainButtonStyle())
                    }
                    VStack(spacing: 4) {
                        ColorPicker("", selection: $bgColor).labelsHidden()
                            .frame(width: 36, height: 36)
                        Text("自定义").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
            }
            Text("系统 Vision 框架智能抠图，自动填充所选背景色")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    private var translationSection: some View {
        VStack(spacing: 20) {
            Text("选择翻译方式")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                TranslationModeButton(title: "屏幕截图翻译", subtitle: "选取屏幕任意区域进行 OCR 识别并翻译", icon: "camera.viewfinder") {
                    isPresented = false
                    onConfirm("screen")
                }
                
                TranslationModeButton(title: "本地图片翻译", subtitle: "选择一张或多张本地图片进行批量翻译", icon: "photo.on.rectangle") {
                    isPresented = false
                    onConfirm("file")
                }
            }
        }
    }

    private var titleText: String {
        switch type {
        case .imageProcess: return "图像批量处理"
        case .videoTranscode: return "视频转码参数"
        case .idPhoto: return "证件照智能换底"
        case .gridSlice: return "多视图切割"
        case .translation: return "图片翻译"
        }
    }

    private func handleConfirm() {
        isPresented = false
        switch type {
        case .imageProcess:
            onConfirm((imageScale, imageFormat))
        case .videoTranscode:
            onConfirm((videoRes, videoFormat, videoQuality))
        case .idPhoto:
            onConfirm(bgColor)
        case .gridSlice:
            if let p = selectedPreset {
                if p.id == "custom" {
                    onConfirm((customRows, customCols))
                } else {
                    onConfirm((p.rows, p.cols))
                }
            }
        case .translation:
            break // Handled in section
        }
    }
}

struct TranslationModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.8 : 0.4))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(isHovered ? 0.5 : 0), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}

struct ConfigRow<Content: View>: View {
    let title: String
    let content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            content
        }
    }
}

struct ColorButton: View {
    let color: Color; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Circle().fill(color).frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.primary, lineWidth: isSelected ? 2 : 0))
                .shadow(radius: 2)
        }.buttonStyle(PlainButtonStyle())
    }
}
