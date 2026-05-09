import Foundation
import SwiftUI

enum AppLanguage: String {
    case en = "English"
    case zh = "中文"
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage = .zh
    
    func toggleLanguage() {
        currentLanguage = currentLanguage == .zh ? .en : .zh
    }
    
    func t(_ key: String) -> String {
        let translations: [String: [AppLanguage: String]] = [
            // Tabs
            "tab_history": [.zh: "剪贴板", .en: "History"],
            "tab_toolbox": [.zh: "工具箱", .en: "Toolbox"],
            "tab_settings": [.zh: "设置", .en: "Settings"],
            
            // History
            "history_title": [.zh: "剪贴板历史", .en: "Clipboard History"],
            "history_clear": [.zh: "清空", .en: "Clear"],
            "history_empty": [.zh: "暂无记录。", .en: "No history yet."],
            "history_copied": [.zh: "已复制！", .en: "Copied!"],
            
            // Toolbox - Creator
            "tb_creator_tools": [.zh: "创作者工具", .en: "Creator Tools"],
            "tb_video_extract": [.zh: "视频抽帧提取", .en: "Video Frame Extractor"],
            "tb_video_extract_desc": [.zh: "将视频精准拆分为单帧图像", .en: "Split video into individual frames"],
            "tb_speech": [.zh: "语音转文字", .en: "Speech to Text"],
            "tb_speech_desc": [.zh: "实时录音并自动复制到剪贴板", .en: "Dictate and copy to clipboard"],
            "tb_ocr": [.zh: "屏幕区域 OCR", .en: "Screen Region OCR"],
            "tb_ocr_desc": [.zh: "框选屏幕任意区域提取文字", .en: "Select a screen region to extract text"],
            "tb_translate": [.zh: "智能翻译", .en: "Smart Translate"],
            "tb_translate_desc": [.zh: "一键翻译剪贴板内容（支持中英互译）", .en: "Translate clipboard text (CN/EN)"],
            "tb_capture": [.zh: "屏幕截图与标注", .en: "Screenshot & Annotate"],
            "tb_capture_desc": [.zh: "系统级截图并直接打开画笔标注面板", .en: "Capture and open native markup tools"],
            "tb_image": [.zh: "批量图像与切片", .en: "Image & Grid Processor"],
            "tb_image_desc": [.zh: "格式转换、精准宫格切分、尺寸调整", .en: "Format convert, precision grid slice, resize"],
            "tb_image_edit": [.zh: "图片编辑与裁剪", .en: "Edit & Crop Image"],
            "tb_image_edit_desc": [.zh: "手动框选裁剪、标注、打马赛克", .en: "Manually crop, annotate, or blur"],
            "tb_audio_extract": [.zh: "视频提取音频", .en: "Extract Audio"],
            "tb_audio_extract_desc": [.zh: "将视频文件无损转换为音频", .en: "Convert video to audio files"],
            "tb_downloader": [.zh: "媒体链接提取", .en: "Media Downloader"],
            "tb_downloader_desc": [.zh: "粘贴视频链接提取视频或音频", .en: "Paste link to extract media"],
            "tb_pdf_merge": [.zh: "文档合并 (PDF)", .en: "Merge PDFs"],
            "tb_pdf_merge_desc": [.zh: "将多个 PDF 文件合并为一个新文件", .en: "Merge multiple PDF files into one"],
            
            // Toolbox - Dev
            "tb_dev_tools": [.zh: "实用工具", .en: "Utilities"],
            "tb_color": [.zh: "屏幕取色器", .en: "Color Picker"],
            "tb_color_desc": [.zh: "拾取屏幕颜色并复制 HEX 码", .en: "Pick a color and copy HEX"],
            "tb_json": [.zh: "格式化 JSON", .en: "Format JSON"],
            "tb_json_desc": [.zh: "格式化剪贴板中的 JSON 文本", .en: "Format clipboard JSON text"],
            "tb_awake": [.zh: "防休眠", .en: "Keep Awake"],
            "tb_awake_on": [.zh: "防休眠 (已开启)", .en: "Keep Awake (ON)"],
            "tb_awake_desc": [.zh: "防止您的 Mac 自动息屏休眠", .en: "Prevent Mac from sleeping"],
            
            // Settings
            "set_title": [.zh: "偏好设置", .en: "Settings"],
            "set_language": [.zh: "界面语言", .en: "Language"],
            "set_lang_desc": [.zh: "切换中英文显示", .en: "Toggle between English and Chinese"],
            "set_save_path": [.zh: "默认保存位置", .en: "Save Location"],
            "set_save_path_desc": [.zh: "所有提取的文件将保存至此目录", .en: "All files will be saved here"],
            "set_hotkeys": [.zh: "全局快捷键 (Beta)", .en: "Global Hotkeys"],
            "set_hotkeys_desc": [.zh: "快速唤起截图、OCR、翻译等工具", .en: "Shortcuts for capture, OCR, translate"],
            "set_about": [.zh: "技术支持与反馈", .en: "Support & Feedback"],
            "set_version": [.zh: "版本 1.2.0 | Created by Drip", .en: "Version 1.2.0 | Created by Drip"],
            "set_feedback_desc": [.zh: "如果您在使用过程中遇到任何问题，或有关于效率提升的绝佳想法，欢迎扫码添加我的微信。期待与您的交流！", .en: "If you encounter any issues or have brilliant ideas for workflow improvements, feel free to scan the QR code to connect with me."],
            "set_scan": [.zh: "扫一扫，添加好友", .en: "Scan to add friend"],
            
            // Messages
            "msg_color": [.zh: "正在打开取色器...", .en: "Opening color picker..."],
            "msg_json_ok": [.zh: "JSON 格式化成功并已复制！", .en: "JSON formatted and copied!"],
            "msg_json_err": [.zh: "剪贴板中没有有效的 JSON", .en: "Invalid JSON in clipboard"],
            "msg_ocr_ok": [.zh: "文字已提取并复制！", .en: "Text copied to clipboard!"],
            "msg_ocr_err": [.zh: "未找到任何文字", .en: "No text found."],
            "msg_listen": [.zh: "正在聆听...", .en: "Listening..."],
            "msg_processing": [.zh: "处理中...", .en: "Processing..."],
            "msg_extracting": [.zh: "提取中...", .en: "Extracting..."],
            "msg_translate_ok": [.zh: "翻译成功并已复制！", .en: "Translated & copied!"],
            "msg_translate_err": [.zh: "翻译失败或剪贴板为空", .en: "Translation failed or empty"]
        ]
        
        return translations[key]?[currentLanguage] ?? key
    }
}
