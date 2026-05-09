import Foundation

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    
    func downloadMedia(from urlString: String, saveTo saveUrl: URL, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false, "无效的 URL")
            return
        }
        
        DispatchQueue.main.async {
            self.isDownloading = true
            self.progress = 0.0
        }
        
        // Check if yt-dlp exists in bundle
        if let ytDlpPath = Bundle.main.path(forResource: "yt-dlp", ofType: "") {
            let task = Process()
            task.launchPath = ytDlpPath
            task.arguments = ["-o", "%(title)s.%(ext)s", "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best", urlString]
            task.currentDirectoryPath = SettingsManager.shared.savePath
            
            task.terminationHandler = { process in
                DispatchQueue.main.async {
                    self.isDownloading = false
                    if process.terminationStatus == 0 {
                        completion(true, "媒体提取成功 (yt-dlp)")
                    } else {
                        completion(false, "提取失败，请检查链接或网络")
                    }
                }
            }
            
            do {
                try task.run()
            } catch {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    completion(false, "解析引擎启动失败")
                }
            }
            return
        }
        
        // Fallback to URLSession
        let task = URLSession.shared.downloadTask(with: url) { localUrl, response, error in
            if let localUrl = localUrl, let httpResponse = response as? HTTPURLResponse, error == nil {
                let mimeType = httpResponse.mimeType ?? ""
                let isHTML = mimeType.contains("text/html")
                
                var fileName = response?.suggestedFilename ?? "downloaded_media_\(Int(Date().timeIntervalSince1970))"
                if isHTML && !fileName.hasSuffix(".html") {
                    fileName += ".html"
                }
                
                let destination = SettingsManager.shared.saveUrl.appendingPathComponent(fileName)
                
                try? FileManager.default.removeItem(at: destination)
                do {
                    try FileManager.default.moveItem(at: localUrl, to: destination)
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        if isHTML {
                            completion(false, "仅支持直链，已为您保存网页源码 (缺失解析内核)")
                        } else {
                            completion(true, "下载成功: \(fileName)")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        completion(false, "保存失败")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    completion(false, error?.localizedDescription ?? "下载失败")
                }
            }
        }
        
        task.resume()
    }
}
