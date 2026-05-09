import SwiftUI
import UniformTypeIdentifiers

enum ConfigType {
    case imageProcess
    case videoTranscode
    case idPhoto
    case gridSlice
}

struct ToolConfigView: View {
    let type: ConfigType
    let urls: [URL]
    @Binding var isPresented: Bool
    var onConfirm: (Any) -> Void
    
    // Image Config State
    @State private var imageScale: Double = 1.0
    @State private var imageFormat: UTType = .png
    
    // Video Config State
    @State private var videoRes: String = "1080p"
    @State private var videoFormat: String = "mp4"
    @State private var videoQuality: String = "Medium"
    
    // ID Photo State
    @State private var bgColor: Color = .blue
    
    // Grid Slice State
    @State private var rows: Int = 3
    @State private var cols: Int = 3
    
    var body: some View {
        VStack(spacing: 24) {
            headerView
            
            ScrollView {
                VStack(spacing: 20) {
                    if type == .imageProcess {
                        imageConfigSection
                    } else if type == .videoTranscode {
                        videoConfigSection
                    } else if type == .idPhoto {
                        idPhotoSection
                    } else if type == .gridSlice {
                        gridSliceSection
                    }
                }
                .padding(.horizontal, 24)
            }
            
            footerView
        }
        .frame(width: 400)
        .padding(.vertical, 24)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
    
    private var headerView: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
    }
    
    private var footerView: some View {
        Button(action: confirmAction) {
            Text("开始处理 (\(urls.count) 个文件)")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 24)
    }
    
    private var imageConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConfigRow(title: "缩放比例") {
                Picker("", selection: $imageScale) {
                    Text("100% (原图)").tag(1.0)
                    Text("75%").tag(0.75)
                    Text("50% (推荐)").tag(0.5)
                    Text("25% (小图)").tag(0.25)
                }
                .pickerStyle(.segmented)
            }
            
            ConfigRow(title: "输出格式") {
                Picker("", selection: $imageFormat) {
                    Text("PNG").tag(UTType.png)
                    Text("JPEG").tag(UTType.jpeg)
                    Text("HEIC").tag(UTType.heic)
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
        }
    }
    
    private var gridSliceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ConfigRow(title: "行数 (Rows)") {
                    Stepper("\(rows)", value: $rows, in: 1...10)
                }
                Spacer()
                ConfigRow(title: "列数 (Cols)") {
                    Stepper("\(cols)", value: $cols, in: 1...10)
                }
            }
            Text("常用于朋友圈 9 宫格 (3x3)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var videoConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConfigRow(title: "分辨率") {
                Picker("", selection: $videoRes) {
                    Text("原分辨率").tag("original")
                    Text("4K (3840x2160)").tag("2160p")
                    Text("2K (2560x1440)").tag("1440p")
                    Text("1080p (1920x1080)").tag("1080p")
                    Text("720p (1280x720)").tag("720p")
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }
            
            ConfigRow(title: "输出格式") {
                Picker("", selection: $videoFormat) {
                    Text("MP4 (H.264/AAC)").tag("mp4")
                    Text("MOV (Apple ProRes)").tag("mov")
                    Text("GIF (High Quality)").tag("gif")
                    Text("WebM").tag("webm")
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }
            
            ConfigRow(title: "编码预设 (Speed/Quality)") {
                Picker("", selection: $videoQuality) {
                    Text("极慢 (高画质)").tag("veryslow")
                    Text("中等 (平衡)").tag("medium")
                    Text("极快 (低画质)").tag("ultrafast")
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var idPhotoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择背景颜色")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                ColorButton(color: .blue, isSelected: bgColor == .blue) { bgColor = .blue }
                ColorButton(color: .red, isSelected: bgColor == .red) { bgColor = .red }
                ColorButton(color: .white, isSelected: bgColor == .white) { bgColor = .white }
                ColorPicker("自定义", selection: $bgColor)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("智能抠图后将自动应用选定底色")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var title: String {
        switch type {
        case .imageProcess: return "图像批量处理"
        case .videoTranscode: return "视频转码设置"
        case .idPhoto: return "证件照智能换底"
        case .gridSlice: return "九宫格裁剪"
        }
    }
    
    private func confirmAction() {
        isPresented = false
        switch type {
        case .imageProcess:
            onConfirm((imageScale, imageFormat))
        case .videoTranscode:
            onConfirm((videoRes, videoFormat, videoQuality))
        case .idPhoto:
            onConfirm(bgColor)
        case .gridSlice:
            onConfirm((rows, cols))
        }
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
            Text(title).font(.subheadline).foregroundColor(.secondary)
            content
        }
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().stroke(Color.primary, lineWidth: isSelected ? 2 : 0)
                )
                .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
