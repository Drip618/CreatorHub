import Foundation
import AppKit
import UniformTypeIdentifiers
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

enum ImageAction {
    case convertFormat(UTType)
    case resize(scale: Double)
    case crop(ratio: Double) // width/height
    case sliceGrid(rows: Int, columns: Int)
    case idPhotoMaker(color: CIColor)
}

class ImageProcessor: ObservableObject {
    static let shared = ImageProcessor()
    
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    
    func processImages(urls: [URL], action: ImageAction, saveTo saveUrl: URL, completion: @escaping (Bool) -> Void) {
        guard !isProcessing, !urls.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.isProcessing = true
            self.progress = 0.0
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let folderName = "图片处理_\(Int(Date().timeIntervalSince1970))"
            let outputFolder = SettingsManager.shared.saveUrl.appendingPathComponent(folderName)
            
            do {
                try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion(false)
                }
                return
            }
            
            var completedCount = 0
            
            for url in urls {
                autoreleasepool {
                    guard let image = NSImage(contentsOf: url),
                          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                        completedCount += 1
                        return
                    }
                    
                    var finalImages: [CGImage] = []
                    
                    switch action {
                    case .resize(let scale):
                        let finalSize = CGSize(width: CGFloat(Double(cgImage.width) * scale), height: CGFloat(Double(cgImage.height) * scale))
                        if let resized = self.resizeImage(cgImage, to: finalSize) {
                            finalImages = [resized]
                        }
                    case .crop(let ratio):
                        if let cropped = self.cropImage(cgImage, toRatio: ratio) {
                            finalImages = [cropped]
                        }
                    case .convertFormat(_):
                        finalImages = [cgImage]
                    case .sliceGrid(let rows, let cols):
                        finalImages = self.sliceImage(cgImage, rows: rows, columns: cols)
                    case .idPhotoMaker(let color):
                        if let idPhoto = self.createIDPhoto(cgImage, bgColor: color) {
                            finalImages = [idPhoto]
                        }
                    }
                    
                    if finalImages.isEmpty { finalImages = [cgImage] }
                    
                    // Determine output format
                    let targetType: UTType
                    if case .convertFormat(let utType) = action {
                        targetType = utType
                    } else {
                        targetType = .png 
                    }
                    
                    let ext = targetType.preferredFilenameExtension ?? "png"
                    let baseName = url.deletingPathExtension().lastPathComponent
                    
                    for (index, img) in finalImages.enumerated() {
                        let suffix = finalImages.count > 1 ? String(format: "_%02d", index + 1) : "_processed"
                        let fileName = baseName + suffix + "." + ext
                        let fileURL = outputFolder.appendingPathComponent(fileName)
                        
                        let newNsImage = NSImage(cgImage: img, size: CGSize(width: img.width, height: img.height))
                        self.saveImage(newNsImage, to: fileURL, format: targetType)
                    }
                    
                    completedCount += 1
                    let currentProgress = Double(completedCount) / Double(urls.count)
                    DispatchQueue.main.async {
                        self.progress = currentProgress
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(true)
            }
        }
    }
    
    private func sliceImage(_ cgImage: CGImage, rows: Int, columns: Int) -> [CGImage] {
        var slices: [CGImage] = []
        guard rows > 0, columns > 0 else { return [cgImage] }
        
        let sliceWidth = cgImage.width / columns
        let sliceHeight = cgImage.height / rows
        
        for row in 0..<rows {
            for col in 0..<columns {
                let rect = CGRect(x: col * sliceWidth,
                                  y: row * sliceHeight,
                                  width: sliceWidth,
                                  height: sliceHeight)
                if let cropped = cgImage.cropping(to: rect) {
                    slices.append(cropped)
                }
            }
        }
        return slices
    }
    
    private func resizeImage(_ cgImage: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
    
    private func cropImage(_ cgImage: CGImage, toRatio targetRatio: Double) -> CGImage? {
        let originalWidth = Double(cgImage.width)
        let originalHeight = Double(cgImage.height)
        let originalRatio = originalWidth / originalHeight
        
        var cropWidth = originalWidth
        var cropHeight = originalHeight
        
        if originalRatio > targetRatio {
            cropWidth = originalHeight * targetRatio
        } else {
            cropHeight = originalWidth / targetRatio
        }
        
        let cropRect = CGRect(
            x: (originalWidth - cropWidth) / 2.0,
            y: (originalHeight - cropHeight) / 2.0,
            width: cropWidth,
            height: cropHeight
        )
        
        return cgImage.cropping(to: cropRect)
    }
    
    private func createIDPhoto(_ cgImage: CGImage, bgColor: CIColor) -> CGImage? {
        if #available(macOS 12.0, *) {
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = .accurate
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                guard let maskObservation = request.results?.first as? VNPixelBufferObservation else { return cgImage }
                
                let maskPixelBuffer = maskObservation.pixelBuffer
                let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
                let originalImage = CIImage(cgImage: cgImage)
                
                let scaleX = originalImage.extent.width / maskImage.extent.width
                let scaleY = originalImage.extent.height / maskImage.extent.height
                let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                
                let background = CIImage(color: bgColor).cropped(to: originalImage.extent)
                
                let blendFilter = CIFilter(name: "CIBlendWithMask")!
                blendFilter.setValue(originalImage, forKey: kCIInputImageKey)
                blendFilter.setValue(background, forKey: kCIInputBackgroundImageKey)
                blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
                
                if let output = blendFilter.outputImage {
                    let context = CIContext(options: nil)
                    if let resultCG = context.createCGImage(output, from: output.extent) {
                        return resultCG
                    }
                }
            } catch {
                print("Segmentation failed: \(error)")
            }
        }
        return cgImage
    }
    
    private func saveImage(_ image: NSImage, to url: URL, format: UTType) {
        if format == .heic {
            if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                if let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.heic.identifier as CFString, 1, nil) {
                    CGImageDestinationAddImage(destination, cgImage, nil)
                    CGImageDestinationFinalize(destination)
                    return
                }
            }
        }
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return }
        
        let type: NSBitmapImageRep.FileType
        var properties: [NSBitmapImageRep.PropertyKey: Any] = [:]
        
        if format == .png {
            type = .png
        } else if format == .tiff {
            type = .tiff
        } else {
            type = .jpeg
            properties[.compressionFactor] = 0.9
        }
        
        if let data = bitmap.representation(using: type, properties: properties) {
            try? data.write(to: url)
        }
    }
}
