import SwiftUI
import AppKit
import AVFoundation

struct WatermarkSelectionView: View {
    let url: URL
    let isVideo: Bool
    @State private var image: NSImage?
    @State private var rects: [CGRect] = []
    @State private var currentRect: CGRect?
    @State private var startPoint: CGPoint?
    @State private var viewSize: CGSize = .zero
    
    var onConfirm: ([CGRect]) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isVideo ? "视频去水印选择" : "图片去水印选择")
                    .font(.headline)
                Spacer()
                Menu("智能预设") {
                    Button("抖音/TikTok (双角模式)") { addTikTokPresets(dynamic: false) }
                    Button("抖音/TikTok (动态跳动全覆盖)") { addTikTokPresets(dynamic: true) }
                    Button("视频中心/台标") { addCenterPreset() }
                }
                .menuStyle(.borderedButton)
                
                Button("清空") { rects.removeAll() }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            ZStack(alignment: .topLeading) {
                if let nsImage = image {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(GeometryReader { geo in
                            Color.clear.onAppear { self.viewSize = geo.size }
                                .onChange(of: geo.size) { self.viewSize = $0 }
                        })
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if startPoint == nil { startPoint = value.startLocation }
                                    let origin = CGPoint(x: min(value.startLocation.x, value.location.x),
                                                         y: min(value.startLocation.y, value.location.y))
                                    let size = CGSize(width: abs(value.location.x - value.startLocation.x),
                                                      height: abs(value.location.y - value.startLocation.y))
                                    currentRect = CGRect(origin: origin, size: size)
                                }
                                .onEnded { value in
                                    if let rect = currentRect, rect.width > 5 && rect.height > 5 {
                                        rects.append(rect)
                                    }
                                    currentRect = nil
                                    startPoint = nil
                                }
                        )
                } else {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Draw existing rects
                ForEach(0..<rects.count, id: \.self) { index in
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .background(Color.red.opacity(0.2))
                        .frame(width: rects[index].width, height: rects[index].height)
                        .offset(x: rects[index].minX, y: rects[index].minY)
                        .overlay(
                            Button(action: { rects.remove(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .offset(x: rects[index].width/2, y: -rects[index].height/2)
                        )
                }
                
                // Draw current rect
                if let rect = currentRect {
                    Rectangle()
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.blue.opacity(0.1))
                        .frame(width: rect.width, height: rect.height)
                        .offset(x: rect.minX, y: rect.minY)
                }
            }
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.1))
            
            HStack {
                Button("取消", action: onCancel)
                Spacer()
                Text(isVideo ? "提示: 针对跳动水印，请框选所有可能出现的区域。" : "提示: 涂抹瑕疵区域，系统将自动进行纹理填充。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("开始高清处理") {
                    let scaledRects = convertRectsToImageCoordinates()
                    onConfirm(scaledRects)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(rects.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 800, height: 600)
        .onAppear { loadPreview() }
    }
    
    func loadPreview() {
        if isVideo {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 1, preferredTimescale: 60)
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                self.image = NSImage(cgImage: cgImage, size: .zero)
            }
        } else {
            self.image = NSImage(contentsOf: url)
        }
    }
    
    func addTikTokPresets(dynamic: Bool) {
        let w = viewSize.width * 0.18
        let h = viewSize.height * 0.08
        if dynamic {
            rects.append(CGRect(x: 10, y: 10, width: w, height: h))
            rects.append(CGRect(x: viewSize.width - w - 10, y: 10, width: w, height: h))
            rects.append(CGRect(x: 10, y: viewSize.height - h - 10, width: w, height: h))
            rects.append(CGRect(x: viewSize.width - w - 10, y: viewSize.height - h - 10, width: w, height: h))
        } else {
            rects.append(CGRect(x: 15, y: 15, width: w, height: h))
            rects.append(CGRect(x: viewSize.width - w - 15, y: viewSize.height - h - 15, width: w, height: h))
        }
    }
    
    func addCenterPreset() {
        let w = viewSize.width * 0.3
        let h = viewSize.height * 0.15
        rects.append(CGRect(x: (viewSize.width - w)/2, y: (viewSize.height - h)/2, width: w, height: h))
    }
    
    func convertRectsToImageCoordinates() -> [CGRect] {
        guard let nsImage = image else { return [] }
        let imgSize = nsImage.size
        let viewAspect = viewSize.width / viewSize.height
        let imgAspect = imgSize.width / imgSize.height
        
        var drawWidth = viewSize.width, drawHeight = viewSize.height
        var offsetX: CGFloat = 0, offsetY: CGFloat = 0
        
        if imgAspect > viewAspect {
            drawHeight = viewSize.width / imgAspect
            offsetY = (viewSize.height - drawHeight) / 2
        } else {
            drawWidth = viewSize.height * imgAspect
            offsetX = (viewSize.width - drawWidth) / 2
        }
        
        return rects.map { rect in
            let relativeX = (rect.minX - offsetX) / drawWidth
            let relativeY = (rect.minY - offsetY) / drawHeight
            let relativeW = rect.width / drawWidth
            let relativeH = rect.height / drawHeight
            return CGRect(x: relativeX * imgSize.width, y: relativeY * imgSize.height,
                          width: relativeW * imgSize.width, height: relativeH * imgSize.height)
        }
    }
}
