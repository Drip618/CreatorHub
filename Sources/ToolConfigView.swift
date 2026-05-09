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
    @State private var imageScale: Double = 1.0
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
            headerView

            Divider()

            ScrollView {
                VStack(spacing: 24) {
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
                footerView
            }
        }
        .frame(width: 440)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .onAppear { 
            if selectedPreset == nil { selectedPreset = presets[2] } 
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText).font(.system(size: 18, weight: .bold))
                if type != .translation {
                    Text("\(urls.count) 个文件已准备就绪").font(.caption).foregroundColor(.secondary)
                } else {
                    Text("请选择您需要的翻译任务类型").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var footerView: some View {
        Button(action: handleConfirm) {
            HStack {
                Image(systemName: "play.circle.fill")
                Text("开始执行任务")
                Spacer()
                Text("\(urls.count) 文件").opacity(0.6)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Sections
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ConfigRow(title: "输出尺寸缩放") {
                HStack(spacing: 12) {
                    ForEach([("原图", 1.0), ("75%", 0.75), ("50%", 0.5), ("25%", 0.25)], id: \.0) { label, val in
                        PillButton(title: label, isSelected: imageScale == val) { imageScale = val }
                    }
                }
            }
            ConfigRow(title: "目标存储格式") {
                HStack(spacing: 12) {
                    ForEach([("JPEG", UTType.jpeg), ("PNG", UTType.png), ("HEIC", UTType.heic)], id: \.0) { label, fmt in
                        PillButton(title: label, isSelected: imageFormat == fmt) { imageFormat = fmt }
                    }
                }
            }
        }
    }

    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ConfigRow(title: "宫格裁剪预设") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(presets) { preset in
                        Button(action: { selectedPreset = preset }) {
                            HStack {
                                Image(systemName: preset.icon).frame(width: 20)
                                Text(preset.label).font(.system(size: 13, weight: .medium))
                                Spacer()
                            }
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(selectedPreset?.id == preset.id ? Color.accentColor : Color.primary.opacity(0.1))
                            .foregroundColor(selectedPreset?.id == preset.id ? .white : .primary)
                            .cornerRadius(10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            if selectedPreset?.id == "custom" {
                HStack(spacing: 24) {
                    ConfigRow(title: "行数 (Rows)") {
                        Stepper("\(customRows)", value: $customRows, in: 1...20)
                    }
                    ConfigRow(title: "列数 (Cols)") {
                        Stepper("\(customCols)", value: $customCols, in: 1...20)
                    }
                }
            }
        }
    }

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ConfigRow(title: "输出分辨率") {
                Picker("", selection: $videoRes) {
                    Text("原始分辨率").tag("original")
                    Text("4K Ultra HD").tag("2160p")
                    Text("2K QHD").tag("1440p")
                    Text("1080p FHD").tag("1080p")
                    Text("720p HD").tag("720p")
                }
                .pickerStyle(.menu).labelsHidden()
            }
            ConfigRow(title: "编码格式") {
                HStack(spacing: 10) {
                    ForEach([("MP4", "mp4"), ("MOV", "mov"), ("GIF", "gif")], id: \.0) { label, fmt in
                        PillButton(title: label, isSelected: videoFormat == fmt) { videoFormat = fmt }
                    }
                }
            }
        }
    }

    private var idPhotoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ConfigRow(title: "证件照背景颜色") {
                HStack(spacing: 15) {
                    ColorCircle(color: Color(red: 0.26, green: 0.55, blue: 0.90), label: "蓝", isSelected: bgColor == Color(red: 0.26, green: 0.55, blue: 0.90)) { bgColor = Color(red: 0.26, green: 0.55, blue: 0.90) }
                    ColorCircle(color: .red, label: "红", isSelected: bgColor == .red) { bgColor = .red }
                    ColorCircle(color: .white, label: "白", isSelected: bgColor == .white) { bgColor = .white }
                    ColorPicker("", selection: $bgColor).labelsHidden()
                }
            }
        }
    }

    private var translationSection: some View {
        HStack(spacing: 20) {
            TranslationModeButton(title: "屏幕截图翻译", subtitle: "选取屏幕区域翻译", icon: "camera.viewfinder") {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onConfirm("screen")
                }
            }
            TranslationModeButton(title: "本地图片翻译", subtitle: "选择本地文件翻译", icon: "photo.on.rectangle") {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch type {
            case .imageProcess: onConfirm((imageScale, imageFormat))
            case .videoTranscode: onConfirm((videoRes, videoFormat, videoQuality))
            case .idPhoto: onConfirm(bgColor)
            case .gridSlice:
                if let p = selectedPreset {
                    onConfirm(p.id == "custom" ? (customRows, customCols) : (p.rows, p.cols))
                }
            case .translation: break
            }
        }
    }
}

// MARK: - Components
struct PillButton: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.primary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
}

struct ColorCircle: View {
    let color: Color; let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        VStack(spacing: 4) {
            Button(action: action) {
                Circle().fill(color).frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: isSelected ? 3 : 0))
                    .shadow(radius: 2)
                    .contentShape(Circle())
            }
            .buttonStyle(.borderless)
            Text(label).font(.system(size: 10)).foregroundColor(.secondary)
        }
    }
}

struct TranslationModeButton: View {
    let title: String; let subtitle: String; let icon: String; let action: () -> Void
    @State private var isHovered = false
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 32)).foregroundColor(.accentColor)
                VStack(spacing: 4) {
                    Text(title).font(.system(size: 14, weight: .bold))
                    Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 140).padding().background(Color.primary.opacity(isHovered ? 0.1 : 0.05)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor.opacity(isHovered ? 0.5 : 0), lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless).onHover { isHovered = $0 }
    }
}

struct ConfigRow<Content: View>: View {
    let title: String; let content: Content
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).textCase(.uppercase)
            content
        }
    }
}
