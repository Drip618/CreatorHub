import Foundation
import Vision
import AppKit

class OCRManager: ObservableObject {
    static let shared = OCRManager()
    
    @Published var isRecognizing = false
    
    func recognizeTextFromScreen(completion: @escaping (String?) -> Void) {
        guard !isRecognizing else { return }
        
        DispatchQueue.main.async {
            self.isRecognizing = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Trigger interactive screen capture to clipboard
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-i", "-c"]
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                DispatchQueue.main.async {
                    self.isRecognizing = false
                    completion(nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                // Read the image from clipboard
                guard let imgData = NSPasteboard.general.data(forType: .tiff),
                      let image = NSImage(data: imgData),
                      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    self.isRecognizing = false
                    completion(nil)
                    return
                }
                
                let request = VNRecognizeTextRequest { request, error in
                    guard error == nil else {
                        DispatchQueue.main.async {
                            self.isRecognizing = false
                            completion(nil)
                        }
                        return
                    }
                    
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let recognizedText = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }.joined(separator: "\n")
                    
                    DispatchQueue.main.async {
                        self.isRecognizing = false
                        if !recognizedText.isEmpty {
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(recognizedText, forType: .string)
                            completion(recognizedText)
                        } else {
                            completion(nil)
                        }
                    }
                }
                
                request.recognitionLevel = .accurate
                if #available(macOS 11.0, *) {
                    request.recognitionLanguages = ["zh-Hans", "en-US"]
                }
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try handler.perform([request])
                    } catch {
                        DispatchQueue.main.async {
                            self.isRecognizing = false
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    func recognizeTextFromURL(_ url: URL, completion: @escaping (String?) -> Void) {
        guard !isRecognizing else { return }
        
        DispatchQueue.main.async {
            self.isRecognizing = true
        }
        
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            DispatchQueue.main.async {
                self.isRecognizing = false
                completion(nil)
            }
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    self.isRecognizing = false
                    completion(nil)
                }
                return
            }
            
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.isRecognizing = false
                completion(recognizedText.isEmpty ? nil : recognizedText)
            }
        }
        
        request.recognitionLevel = .accurate
        if #available(macOS 11.0, *) {
            request.recognitionLanguages = ["zh-Hans", "en-US"]
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isRecognizing = false
                    completion(nil)
                }
            }
        }
    }
}
