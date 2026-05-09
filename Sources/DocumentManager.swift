import Foundation
import PDFKit
import AppKit

class DocumentManager: ObservableObject {
    static let shared = DocumentManager()
    
    @Published var isProcessing = false
    
    func mergePDFs(urls: [URL], saveTo saveUrl: URL, completion: @escaping (Bool) -> Void) {
        guard !urls.isEmpty else {
            completion(false)
            return
        }
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let mergedPDF = PDFDocument()
            var currentPageIndex = 0
            
            for url in urls {
                if let pdf = PDFDocument(url: url) {
                    let pageCount = pdf.pageCount
                    for i in 0..<pageCount {
                        if let page = pdf.page(at: i) {
                            mergedPDF.insert(page, at: currentPageIndex)
                            currentPageIndex += 1
                        }
                    }
                }
            }
            
            let outputURL = SettingsManager.shared.saveUrl.appendingPathComponent("合并文档_\(Int(Date().timeIntervalSince1970)).pdf")
            
            let success = mergedPDF.write(to: outputURL)
            
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(success)
            }
        }
    }
}
