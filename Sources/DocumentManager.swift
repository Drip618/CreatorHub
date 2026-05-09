import Foundation
import PDFKit
import AppKit

class DocumentManager: ObservableObject {
    static let shared = DocumentManager()
    
    @Published var isProcessing = false
    
    func mergeFiles(urls: [URL], completion: @escaping (Bool, String) -> Void) {
        guard !urls.isEmpty else {
            completion(false, "未选择文件")
            return
        }
        
        DispatchQueue.main.async { self.isProcessing = true }
        
        let extensions = Set(urls.map { $0.pathExtension.lowercased() })
        
        if extensions.contains("pdf") {
            mergePDFs(urls: urls, completion: completion)
        } else if extensions.contains("xlsx") || extensions.contains("csv") {
            mergeTables(urls: urls, completion: completion)
        } else {
            mergeTextDocs(urls: urls, completion: completion)
        }
    }
    
    private func mergePDFs(urls: [URL], completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let mergedPDF = PDFDocument()
            var pageIndex = 0
            for url in urls {
                if let pdf = PDFDocument(url: url) {
                    for i in 0..<pdf.pageCount {
                        if let page = pdf.page(at: i) {
                            mergedPDF.insert(page, at: pageIndex)
                            pageIndex += 1
                        }
                    }
                }
            }
            let outUrl = SettingsManager.shared.saveUrl.appendingPathComponent("合并文档_\(Int(Date().timeIntervalSince1970)).pdf")
            let success = mergedPDF.write(to: outUrl)
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(success, success ? "PDF 合并成功" : "合并失败")
            }
        }
    }
    
    private func mergeTextDocs(urls: [URL], completion: @escaping (Bool, String) -> Void) {
        // Use Pandoc to merge MD/Docx/HTML
        guard let pandocPath = Bundle.main.path(forResource: "pandoc", ofType: "") else {
            DispatchQueue.main.async { self.isProcessing = false; completion(false, "转换引擎缺失") }
            return
        }
        
        let outName = "全能合并文档_\(Int(Date().timeIntervalSince1970)).docx"
        let outUrl = SettingsManager.shared.saveUrl.appendingPathComponent(outName)
        
        let task = Process()
        task.launchPath = pandocPath
        task.arguments = urls.map { $0.path } + ["-o", outUrl.path]
        
        task.terminationHandler = { proc in
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(proc.terminationStatus == 0, proc.terminationStatus == 0 ? "文档合并成功" : "合并失败")
            }
        }
        
        do { try task.run() } catch {
            DispatchQueue.main.async { self.isProcessing = false; completion(false, "引擎启动失败") }
        }
    }
    
    private func mergeTables(urls: [URL], completion: @escaping (Bool, String) -> Void) {
        // Simple CSV merge for now (Universal Table Merging)
        DispatchQueue.global(qos: .userInitiated).async {
            var combinedContent = ""
            for (index, url) in urls.enumerated() {
                if let content = try? String(contentsOf: url) {
                    if index == 0 {
                        combinedContent += content
                    } else {
                        // Skip header for subsequent files
                        let lines = content.components(separatedBy: .newlines)
                        if lines.count > 1 {
                            combinedContent += "\n" + lines.dropFirst().joined(separator: "\n")
                        }
                    }
                }
            }
            let outUrl = SettingsManager.shared.saveUrl.appendingPathComponent("合并表格_\(Int(Date().timeIntervalSince1970)).csv")
            do {
                try combinedContent.write(to: outUrl, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { self.isProcessing = false; completion(true, "表格(CSV)合并成功") }
            } catch {
                DispatchQueue.main.async { self.isProcessing = false; completion(false, "合并失败") }
            }
        }
    }
    func downgradeXML(url: URL, targetVersion: String, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var content = try String(contentsOf: url, encoding: .utf8)
                
                // Generic XML version replacement logic (FCPX/Premiere)
                // Pattern: version="1.10" -> version="1.9"
                let pattern = "version=\"[^\"]+\""
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(content.startIndex..<content.endIndex, in: content)
                
                content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "version=\"\(targetVersion)\"")
                
                let outUrl = SettingsManager.shared.saveUrl.appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)_降级版.\(url.pathExtension)")
                try content.write(to: outUrl, atomically: true, encoding: .utf8)
                
                DispatchQueue.main.async { completion(true, "XML 已成功降级至 \(targetVersion)") }
            } catch {
                DispatchQueue.main.async { completion(false, "XML 降级处理失败") }
            }
        }
    }
}
