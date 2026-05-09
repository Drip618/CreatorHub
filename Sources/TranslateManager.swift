import Foundation
import AppKit

class TranslateManager: ObservableObject {
    static let shared = TranslateManager()
    
    @Published var isTranslating = false
    
    func translateClipboard(completion: @escaping (String?) -> Void) {
        let pb = NSPasteboard.general
        guard let text = pb.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(nil)
            return
        }
        
        translate(text: text) { translatedText in
            if let result = translatedText {
                DispatchQueue.main.async {
                    pb.clearContents()
                    pb.setString(result, forType: .string)
                    completion(result)
                }
            } else {
                completion(nil)
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
