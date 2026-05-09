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
        case delogo(rects: [CGRect])
        case audioPurify
        case customTranscode(res: String, format: String, quality: String)
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
        case .delogo(let rects):
            outputFileName = "高清去水印_\(Int(Date().timeIntervalSince1970)).mp4"
            let filterString = rects.map { "delogo=x=\(Int($0.origin.x)):y=\(Int($0.origin.y)):w=\(Int($0.size.width)):h=\(Int($0.size.height)):band=10" }.joined(separator: ",")
            arguments = ["-i", url.path, "-vf", filterString, "-c:a", "copy", "-y", saveUrl.appendingPathComponent(outputFileName).path]
        case .audioPurify:
            outputFileName = "音频净化_\(Int(Date().timeIntervalSince1970)).mp3"
            arguments = ["-i", url.path, "-af", "anlmdn,pan=stereo|c0=c0-c1|c1=c1-c0", "-q:a", "0", "-y", saveUrl.appendingPathComponent(outputFileName).path]
        case .customTranscode(let res, let format, let quality):
            let ext = format.lowercased()
            outputFileName = "创作转换_\(Int(Date().timeIntervalSince1970)).\(ext)"
            var args = ["-i", url.path]
            if res != "original" {
                let h = res.replacingOccurrences(of: "p", with: "")
                args += ["-vf", "scale=-2:\(h)"]
            }
            if ext == "gif" {
                args += ["-vf", "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"]
            } else if ext == "mov" {
                args += ["-c:v", "prores_ks", "-profile:v", "3"]
            } else {
                args += ["-c:v", "libx264", "-preset", quality.lowercased(), "-crf", "23"]
            }
            args += ["-y", saveUrl.appendingPathComponent(outputFileName).path]
            arguments = args
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
                    completion(false, "引擎处理失败")
                }
            }
        }
        
        do { try task.run() } catch {
            DispatchQueue.main.async { self.isProcessing = false; completion(false, "引擎启动失败") }
        }
    }
    
    // MARK: - Image Intelligent Inpaint (Texture Aware)
    func inpaintImage(url: URL, rects: [CGRect], completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = NSImage(contentsOf: url),
                  let tiff = image.tiffRepresentation,
                  let ciImage = CIImage(data: tiff) else {
                DispatchQueue.main.async { completion(false, "图片加载失败") }
                return
            }
            
            var currentOutput = ciImage
            let context = CIContext()
            
            for rect in rects {
                let searchRect = rect.insetBy(dx: -rect.width, dy: -rect.height).intersection(ciImage.extent)
                let searchImage = currentOutput.cropped(to: searchRect)
                let medianFilter = CIFilter(name: "CIMedianFilter")!
                medianFilter.setValue(currentOutput, forKey: kCIInputImageKey)
                guard let smoothed = medianFilter.outputImage?.cropped(to: ciImage.extent) else { continue }
                
                let offsetFilter = CIFilter(name: "CIAffineClamp")!
                let transform = CGAffineTransform(translationX: 10, y: 10)
                offsetFilter.setValue(searchImage.transformed(by: transform), forKey: kCIInputImageKey)
                guard let textureSample = offsetFilter.outputImage?.cropped(to: ciImage.extent) else { continue }
                
                let maskImage = CIImage(color: .black).clampedToExtent().cropped(to: ciImage.extent)
                let whiteBox = CIImage(color: .white).cropped(to: rect)
                let combinedMask = whiteBox.composited(over: maskImage)
                
                let blendFilter = CIFilter(name: "CIBlendWithMask")!
                blendFilter.setValue(textureSample, forKey: kCIInputImageKey)
                blendFilter.setValue(smoothed, forKey: kCIInputBackgroundImageKey)
                blendFilter.setValue(combinedMask, forKey: kCIInputMaskImageKey)
                
                if let nextOutput = blendFilter.outputImage { currentOutput = nextOutput }
            }
            
            let outputFileName = "无损修补_\(Int(Date().timeIntervalSince1970)).jpg"
            let destination = SettingsManager.shared.saveUrl.appendingPathComponent(outputFileName)
            
            if let jpegData = context.jpegRepresentation(of: currentOutput, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:]) {
                try? jpegData.write(to: destination)
                DispatchQueue.main.async { completion(true, "图片修补成功: \(outputFileName)") }
            }
        }
    }
    
    // MARK: - Pandoc Document Conversion
    enum PandocAction { case mdToWord; case wordToMd; case htmlToMd }
    func processDocument(url: URL, action: PandocAction, completion: @escaping (Bool, String) -> Void) {
        guard let pandocPath = Bundle.main.path(forResource: "pandoc", ofType: "") else {
            completion(false, "Pandoc 引擎未找到"); return
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
                completion(process.terminationStatus == 0, process.terminationStatus == 0 ? "文档转化成功: \(outputFileName)" : "转换失败")
            }
        }
        try? task.run()
    }
    
    func cleanFCPXCache(urls: [URL], completion: @escaping (Int64) -> Void) {
        DispatchQueue.global(qos: .default).async {
            var freedSpace: Int64 = 0
            let fm = FileManager.default
            for url in urls {
                let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey], options: [.skipsHiddenFiles])
                while let fileUrl = enumerator?.nextObject() as? URL {
                    if fileUrl.path.contains("Render Files") || fileUrl.path.contains("Analysis Files") || fileUrl.path.contains("Transcoded Media") {
                        if let attrs = try? fm.attributesOfItem(atPath: fileUrl.path) { freedSpace += (attrs[.size] as? Int64) ?? 0 }
                        try? fm.removeItem(at: fileUrl)
                    }
                }
            }
            DispatchQueue.main.async { completion(freedSpace) }
        }
    }
    
    func normalizeLoudness(url: URL, completion: @escaping (Bool, String) -> Void) {
        guard let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else { completion(false, "引擎缺失"); return }
        let outName = "标准化音频_\(Int(Date().timeIntervalSince1970)).mp3"
        let outPath = SettingsManager.shared.saveUrl.appendingPathComponent(outName).path
        let task = Process()
        task.launchPath = ffmpegPath
        task.arguments = ["-i", url.path, "-af", "loudnorm=I=-14:LRA=11:tp=-1", "-y", outPath]
        task.terminationHandler = { proc in
            DispatchQueue.main.async { completion(proc.terminationStatus == 0, proc.terminationStatus == 0 ? "标准化完成: \(outName)" : "失败") }
        }
        try? task.run()
    }
}
