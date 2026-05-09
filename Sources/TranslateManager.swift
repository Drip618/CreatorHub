import Foundation
import AppKit

class TranslateManager: ObservableObject {
    static let shared = TranslateManager()
    
    @Published var isTranslating = false
    
    /// 翻译指定文本，结果通过 completion 返回（不修改剪贴板）
    func translateText(_ text: String, completion: @escaping (String?) -> Void) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(nil)
            return
        }
        translate(text: text, completion: completion)
    }
    
    func pickImageAndTranslate() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                OCRManager.shared.recognizeTextFromURL(url) { text in
                    if let t = text {
                        self.translateText(t) { result in
                            FloatingWindowManager.shared.show(title: "图片翻译结果", text: result ?? "翻译失败")
                        }
                    } else {
                        FloatingWindowManager.shared.show(title: "翻译失败", text: "未能识别图中的文字")
                    }
                }
            }
        }
    }
    
    func translate(text: String, completion: @escaping (String?) -> Void) {
        let isChinese = text.range(of: "\\p{Han}", options: .regularExpression) != nil
        let targetLang = isChinese ? "en" : "zh-CN"
        
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=\(targetLang)&dt=t&q=\(encodedText)") else {
            completion(nil)
            return
        }
        
        DispatchQueue.main.async { self.isTranslating = true }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async { self.isTranslating = false }
            
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            var translatedText = ""
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [Any],
                   let sentences = json.first as? [[Any]] {
                    for sentence in sentences {
                        if let textPart = sentence.first as? String {
                            translatedText += textPart
                        }
                    }
                }
            } catch {
                print("Translation JSON parsing error: \(error)")
            }
            
            if !translatedText.isEmpty {
                completion(translatedText)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
}
