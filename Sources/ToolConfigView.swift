import SwiftUI
import UniformTypeIdentifiers

enum ConfigType: Equatable {
    case imageProcess
    case videoTranscode
    case idPhoto
    case gridSlice
    case translation
}

struct GridPreset: Identifiable, Equatable, Hashable {
    let id: String; let label: String; let rows: Int; let cols: Int
    var icon: String {
        switch id {
        case "1x3", "2x3", "3x4": return "rectangle.split.3x1"
        case "3x3", "5x5", "4x8": return "square.grid.3x3"
        default: return "square.grid.3x3"
        }
    }
}

struct ToolConfigView: View {
    let type: ConfigType; let urls: [URL]; @Binding var isPresented: Bool
    var onConfirm: (Any) -> Void

    @State private var imageScale: Double = 1.0
    @State private var imageFormat: UTType = .jpeg
    @State private var videoRes: String = "original"
    @State private var videoFormat: String = "mp4"
    @State private var videoQuality: String = "medium"
    @State private var bgColor: Color = Color(red: 0.26, green: 0.55, blue: 0.90)

    let presets: [GridPreset] = [
        GridPreset(id: "1x3", label: "1×3", rows: 1, cols: 3),
        GridPreset(id: "2x3", label: "2×3", rows: 2, cols: 3),
        GridPreset(id: "3x3", label: "3×3", rows: 3, cols: 3),
        GridPreset(id: "3x4", label: "3×4", rows: 3, cols: 4),
        GridPreset(id: "5x5", label: "5×5", rows: 5, cols: 5),
        GridPreset(id: "4x8", label: "4×8", rows: 4, cols: 8),
        GridPreset(id: "custom", label: "自定义", rows: 3, cols: 3),
    ]
    @State private var selectedPreset: GridPreset? = nil
    @State private var customRows: Int = 3
    @State private var customCols: Int = 3

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleText).font(.system(size: 18, weight: .bold))
                    Text(type == .translation ? "选择翻译来源" : "\(urls.count) 个文件已就绪").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.secondary)
                }.buttonStyle(.borderless)
            }
            .padding(24)
            
            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    if type == .imageProcess { imageSection }
                    else if type == .videoTranscode { videoSection }
                    else if type == .idPhoto { idPhotoSection }
                    else if type == .gridSlice { gridSection }
                    else if type == .translation { translationSection }
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack(spacing: 16) {
                Button("取消") { isPresented = false }
                    .buttonStyle(.bordered).controlSize(.large)
                
                if type != .translation {
                    Button(action: handleConfirm) {
                        Text("开始处理").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                }
            }
            .padding(24)
        }
        .frame(width: 440, height: type == .translation ? 320 : 580)
        .background(Color(NSColor.windowBackgroundColor)) // Solid background for stability
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ConfigRow(title: "缩放比例") {
                Picker("", selection: $imageScale) {
                    Text("原始尺寸").tag(1.0)
                    Text("75%").tag(0.75)
                    Text("50%").tag(0.5)
                    Text("25%").tag(0.25)
                }.pickerStyle(.segmented).labelsHidden()
            }
            ConfigRow(title: "输出格式") {
                Picker("", selection: $imageFormat) {
                    Text("JPEG").tag(UTType.jpeg)
                    Text("PNG").tag(UTType.png)
                    Text("HEIC").tag(UTType.heic)
                }.pickerStyle(.segmented).labelsHidden()
            }
        }
    }

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ConfigRow(title: "分辨率") {
                Picker("", selection: $videoRes) {
                    Text("原始").tag("original")
                    Text("4K").tag("2160p")
                    Text("2K").tag("1440p")
                    Text("1080p").tag("1080p")
                }.pickerStyle(.menu).labelsHidden()
            }
            ConfigRow(title: "格式") {
                Picker("", selection: $videoFormat) {
                    Text("MP4").tag("mp4")
                    Text("MOV").tag("mov")
                    Text("GIF").tag("gif")
                }.pickerStyle(.segmented).labelsHidden()
            }
        }
    }

    private var idPhotoSection: some View {
        ConfigRow(title: "背景颜色") {
            HStack {
                ColorPicker("选择颜色", selection: $bgColor)
                Spacer()
                Button("蓝") { bgColor = Color(red: 0.26, green: 0.55, blue: 0.90) }.buttonStyle(.bordered)
                Button("红") { bgColor = .red }.buttonStyle(.bordered)
                Button("白") { bgColor = .white }.buttonStyle(.bordered)
            }
        }
    }

    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            ConfigRow(title: "宫格预设") {
                Picker("", selection: $selectedPreset) {
                    ForEach(presets) { Text($0.label).tag(Optional($0)) }
                }.pickerStyle(.menu).labelsHidden()
            }
            if selectedPreset?.id == "custom" {
                HStack {
                    Stepper("行: \(customRows)", value: $customRows, in: 1...10)
                    Spacer()
                    Stepper("列: \(customCols)", value: $customCols, in: 1...10)
                }
            }
        }
    }

    private var translationSection: some View {
        VStack(spacing: 16) {
            Button(action: { isPresented = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onConfirm("screen") } }) {
                HStack { Image(systemName: "camera.viewfinder"); Text("屏幕截图翻译"); Spacer() }
                    .padding().frame(maxWidth: .infinity).background(Color.accentColor.opacity(0.1)).cornerRadius(12)
            }.buttonStyle(.plain)
            
            Button(action: { isPresented = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onConfirm("file") } }) {
                HStack { Image(systemName: "photo.on.rectangle"); Text("选择本地图片翻译"); Spacer() }
                    .padding().frame(maxWidth: .infinity).background(Color.primary.opacity(0.05)).cornerRadius(12)
            }.buttonStyle(.plain)
        }
    }

    private var titleText: String {
        switch type {
        case .imageProcess: return "图像批量处理"
        case .videoTranscode: return "视频转码"
        case .idPhoto: return "证件照制作"
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
            case .gridSlice: if let p = selectedPreset { onConfirm(p.id == "custom" ? (customRows, customCols) : (p.rows, p.cols)) }
            case .translation: break
            }
        }
    }
}

struct ConfigRow<Content: View>: View {
    let title: String; let content: Content
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            content
        }
    }
}
