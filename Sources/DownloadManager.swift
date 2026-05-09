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
            // Use specific User-Agent and flags to bypass watermark streams for TikTok/Douyin
            // --no-playlist and specific format selection
            task.arguments = [
                "--user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 14_8 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1",
                "-o", "%(title)s.%(ext)s",
                "-f", "bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]/best",
                "--no-playlist",
                urlString
            ]
            task.currentDirectoryPath = SettingsManager.shared.savePath
            
            task.terminationHandler = { process in
                DispatchQueue.main.async {
                    self.isDownloading = false
                    if process.terminationStatus == 0 {
                        self.autoCleanWatermarkIfPossible(urlString: urlString, completion: completion)
                    } else {
                        completion(false, "提取失败，请检查链接或网络")
                    }
                }
            }
            
            do { try task.run() } catch {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    completion(false, "解析引擎启动失败")
                }
            }
            return
        }
        
        // Fallback to URLSession
        let task = URLSession.shared.downloadTask(with: url) { localUrl, response, error in
            DispatchQueue.main.async { self.isDownloading = false }
            if let localUrl = localUrl, let httpResponse = response as? HTTPURLResponse, error == nil {
                let fileName = response?.suggestedFilename ?? "downloaded_media_\(Int(Date().timeIntervalSince1970))"
                let destination = SettingsManager.shared.saveUrl.appendingPathComponent(fileName)
                
                try? FileManager.default.removeItem(at: destination)
                do {
                    try FileManager.default.moveItem(at: localUrl, to: destination)
                    DispatchQueue.main.async { completion(true, "下载成功: \(fileName)") }
                } catch {
                    DispatchQueue.main.async { completion(false, "保存失败") }
                }
            } else {
                DispatchQueue.main.async { completion(false, error?.localizedDescription ?? "下载失败") }
            }
        }
        task.resume()
    }
    
    private func autoCleanWatermarkIfPossible(urlString: String, completion: @escaping (Bool, String) -> Void) {
        let fileManager = FileManager.default
        let savePath = SettingsManager.shared.savePath
        guard let files = try? fileManager.contentsOfDirectory(atPath: savePath) else {
            completion(true, "媒体下载成功")
            return
        }
        
        let sortedFiles = files.map { (name: $0, path: (savePath as NSString).appendingPathComponent($0)) }
            .compactMap { item -> (name: String, path: String, date: Date)? in
                let attr = try? fileManager.attributesOfItem(atPath: item.path)
                return (item.name, item.path, attr?[.creationDate] as? Date ?? Date.distantPast)
            }
            .sorted { $0.date > $1.date }
        
        guard let latestFile = sortedFiles.first else {
            completion(true, "媒体下载成功")
            return
        }
        
        let lowerUrl = urlString.lowercased()
        if lowerUrl.contains("tiktok.com") || lowerUrl.contains("douyin.com") {
            completion(true, "下载完成！检测到短视频，建议使用「可视化去水印」精准抹除 (自带 TikTok/抖音预设)")
        } else {
            completion(true, "媒体下载成功: \(latestFile.name)")
        }
    }
}
