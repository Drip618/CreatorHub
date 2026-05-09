import Foundation
import AppKit
import CoreGraphics
import ImageIO

class UltimateManager: ObservableObject {
    static let shared = UltimateManager()
    
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    
    // MARK: - FFmpeg Media Processing
    enum FFmpegAction {
        case toGIF
        case compress
        case extractAudio
        case extractFrames
        case transcodeToMP4
    }
    
    func processVideo(url: URL, action: FFmpegAction, completion: @escaping (Bool, String) -> Void) {
        guard let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else {
            completion(false, "FFmpeg 引擎未找到")
            return
        }
        
        DispatchQueue.main.async { self.isProcessing = true; self.progress = 0.0 }
        
        let outputFileName: String
        let arguments: [String]
        let saveUrl = SettingsManager.shared.saveUrl
        
        switch action {
        case .toGIF:
            outputFileName = "转化GIF_\(Int(Date().timeIntervalSince1970)).gif"
            arguments = ["-i", url.path, "-vf", "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse", "-y", saveUrl.appendingPathComponent(outputFileName).path]
        case .compress:
            outputFileName = "无损压缩_\(Int(Date().timeIntervalSince1970)).mp4"
            arguments = ["-i", url.path, "-vcodec", "libx264", "-crf", "28", "-preset", "faster", "-y", saveUrl.appendingPathComponent(outputFileName).path]
        case .extractAudio:
            outputFileName = "提取音频_\(Int(Date().timeIntervalSince1970)).mp3"
            arguments = ["-i", url.path, "-q:a", "0", "-map", "a", "-y", saveUrl.appendingPathComponent(outputFileName).path]
        case .extractFrames:
            let folderName = "视频抽帧_\(Int(Date().timeIntervalSince1970))"
            let folderUrl = saveUrl.appendingPathComponent(folderName)
            try? FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: true)
            arguments = ["-i", url.path, "-vf", "fps=1", "\(folderUrl.path)/frame_%04d.jpg"]
            outputFileName = folderName
        case .transcodeToMP4:
            outputFileName = "格式转换_\(Int(Date().timeIntervalSince1970)).mp4"
            arguments = ["-i", url.path, "-c:v", "copy", "-c:a", "aac", "-y", saveUrl.appendingPathComponent(outputFileName).path]
        }
        
        let task = Process()
        task.launchPath = ffmpegPath
        task.arguments = arguments
        
        task.terminationHandler = { process in
            DispatchQueue.main.async {
                self.isProcessing = false
                if process.terminationStatus == 0 {
                    completion(true, "处理成功: \(outputFileName)")
                } else {
                    completion(false, "FFmpeg 引擎处理失败")
                }
            }
        }
        
        do { try task.run() } catch {
            DispatchQueue.main.async { self.isProcessing = false; completion(false, "引擎启动失败") }
        }
    }
    
    // MARK: - Pandoc Document Conversion
    enum PandocAction {
        case mdToWord
        case wordToMd
        case htmlToMd
    }
    
    func processDocument(url: URL, action: PandocAction, completion: @escaping (Bool, String) -> Void) {
        guard let pandocPath = Bundle.main.path(forResource: "pandoc", ofType: "") else {
            completion(false, "Pandoc 引擎未找到")
            return
        }
        
        DispatchQueue.main.async { self.isProcessing = true }
        
        let outputFileName: String
        switch action {
        case .mdToWord: outputFileName = "转换文档_\(Int(Date().timeIntervalSince1970)).docx"
        case .wordToMd: outputFileName = "转换文档_\(Int(Date().timeIntervalSince1970)).md"
        case .htmlToMd: outputFileName = "转换文档_\(Int(Date().timeIntervalSince1970)).md"
        }
        
        let destination = SettingsManager.shared.saveUrl.appendingPathComponent(outputFileName)
        
        let task = Process()
        task.launchPath = pandocPath
        task.arguments = ["-s", url.path, "-o", destination.path]
        
        task.terminationHandler = { process in
            DispatchQueue.main.async {
                self.isProcessing = false
                if process.terminationStatus == 0 {
                    completion(true, "文档转化成功: \(outputFileName)")
                } else {
                    completion(false, "Pandoc 转换失败")
                }
            }
        }
        
        do { try task.run() } catch {
            DispatchQueue.main.async { self.isProcessing = false; completion(false, "Pandoc 引擎启动失败") }
        }
    }
    
    // MARK: - Privacy EXIF Stripper (Native ImageIO)
    func stripEXIF(from imageUrls: [URL], completion: @escaping (Int) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var successCount = 0
            for url in imageUrls {
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let type = CGImageSourceGetType(source) else { continue }
                let outputFileName = "隐私净化_\(url.lastPathComponent)"
                let destination = SettingsManager.shared.saveUrl.appendingPathComponent(outputFileName)
                guard let dest = CGImageDestinationCreateWithURL(destination as CFURL, type, 1, nil) else { continue }
                
                CGImageDestinationAddImageFromSource(dest, source, 0, [kCGImageDestinationMetadata as String: NSNull()] as CFDictionary)
                if CGImageDestinationFinalize(dest) { successCount += 1 }
            }
            DispatchQueue.main.async { completion(successCount) }
        }
    }
}
