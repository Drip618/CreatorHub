# Creator Hub - 终极多媒体创作者工具箱 (macOS)

Creator Hub 是一款专为创作者设计的 macOS 原生全能工具箱。它集成了最顶尖的开源引擎（FFmpeg, yt-dlp, Pandoc, Vision OCR），通过极简的毛玻璃界面和系统级交互，彻底打通了创作流的最后一步。

## 🚀 项目进化史

1.  **Phase 1: MacCaptureHub** - 初步探索，实现了基础的截图与粘贴板增强功能。
2.  **Phase 2: 多媒体工具箱** - 深度集成二进制引擎，引入了视频压缩、音频提取及 PDF 合并等硬核功能。
3.  **Phase 3: Creator Hub (最终版)** - 实现了极致的系统级交互（划词翻译、鼠标位置浮窗）、右键菜单集成以及企业级代码安全加固。

## 🌟 核心功能

### 🎬 影视后期
*   **全网媒体解析 (yt-dlp)**：一键下载全球主流平台的无损视频。
*   **终极视频工坊 (FFmpeg)**：视频无损压缩、万能转码、秒转高质量 GIF、音画分离。
*   **图片隐私净化**：一键抹除所有图片的 EXIF/GPS 敏感数据，保护隐私。

### 📄 文档创作
*   **划词翻译 (Option+3)**：任意软件选中文字，即刻在鼠标上方弹出悬浮翻译。
*   **屏幕 OCR (Option+2)**：底层 Vision 引擎，极速提取屏幕任意位置的文字。
*   **宇宙文档转换 (Pandoc)**：Word/Markdown/HTML 格式自由互转。
*   **智能 PDF 拼接**：多文档一键合并。

### 🛠️ 开发者与极客工具
*   **屏幕取色**：获取十六进制色值。
*   **防休眠模式**：一键禁止系统进入睡眠。
*   **JSON 格式化**：剪贴板数据一键美化。

## 📦 技术架构
*   **语言**: Swift 5.0 (Native)
*   **框架**: SwiftUI / AppKit / Vision / ScreenCaptureKit
*   **编译优化**: 开启全模块优化 (`-O -whole-module-optimization`)，移除所有符号 (`strip`) 以增强防反编译能力。

## 🛠️ 构建与运行
1. 确保安装了 Xcode 命令行工具。
2. 运行 `./build.sh` 进行编译和打包。
3. 编译产物为 `Creator Hub.app`。

---
*Created by Antigravity AI for Drip.*
