import SwiftUI

struct ContentView: View {
    @ObservedObject var lang = LanguageManager.shared
    @State private var selectedTab = 1
    @State private var showAbout = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Sleek Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cube.transparent.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                    Text("Creator Hub")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                Spacer()
                Button(action: { showAbout.toggle() }) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { h in NSCursor.pointingHand.set() }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Custom Segmented Control
            HStack(spacing: 0) {
                TabButton(title: lang.t("tab_history"), icon: "clock", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: lang.t("tab_toolbox"), icon: "square.grid.2x2", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: lang.t("tab_settings"), icon: "gearshape.fill", isSelected: selectedTab == 2) { selectedTab = 2 }
            }
            .padding(4)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Content
            ZStack {
                if selectedTab == 0 { HistoryView().transition(.opacity) }
                else if selectedTab == 1 { ToolboxView().transition(.opacity) }
                else { SettingsView().transition(.opacity) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 440, height: 720)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .sheet(isPresented: $showAbout) {
            AboutView(isPresented: $showAbout)
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(title).font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
            .cornerRadius(8)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { h in isHovered = h }
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct AboutView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Image(systemName: "cube.transparent.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 4) {
                Text("Creator Hub Native")
                    .font(.title)
                    .fontWeight(.bold)
                Text("v1.0.0 (Ultimate Edition)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .center, spacing: 16) {
                if let image = NSImage(named: "wechat_qr") {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Waiting for QR")
                            .font(.caption)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                }
                Text("扫描二维码，获取独家定制与更多牛逼插件！")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(16)
        }
        .padding(24)
        .frame(width: 360, height: 480)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
}

struct HistoryView: View {
    @ObservedObject var monitor = ClipboardMonitor.shared
    @ObservedObject var lang = LanguageManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(lang.t("history_title"))
                    .font(.headline)
                Spacer()
                Button(action: { monitor.clear() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            if monitor.history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(lang.t("history_empty"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(monitor.history) { item in
                            HistoryRow(item: item)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct HistoryRow: View {
    let item: HistoryItem
    @State private var isHovered = false
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("TEXT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
                Text(item.timestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if copied {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("已复制").font(.body).fontWeight(.bold).foregroundColor(.green)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text(item.content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.primary.opacity(0.9))
            }
        }
        .padding(16)
        .background(isHovered ? Color(NSColor.controlBackgroundColor).opacity(0.9) : Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(isHovered ? 0.1 : 0.05), radius: 5, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { h in isHovered = h; if h { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() } }
        .onTapGesture {
            let pb = NSPasteboard.general; pb.clearContents(); pb.setString(item.content, forType: .string)
            withAnimation { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { withAnimation { copied = false } }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var lang = LanguageManager.shared
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(lang.t("set_title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 24)
                
                VStack(spacing: 0) {
                    ForEach(0..<settings.customHotkeys.count, id: \.self) { index in
                        SettingsRow(icon: "keyboard", title: "自定义快捷键 \(index + 1)", subtitle: settings.getActionName(for: settings.customHotkeys[index].actionId), color: .accentColor) {
                            HStack {
                                Picker("", selection: $settings.customHotkeys[index].actionId) {
                                    Text("未设置").tag(String?.none)
                                    Section(header: Text("创作流")) {
                                        Text("屏幕截图").tag(Optional("screenshot"))
                                        Text("文字识别").tag(Optional("ocr"))
                                        Text("多语言翻译").tag(Optional("translate"))
                                        Text("语音听写").tag(Optional("speech_to_text"))
                                        Text("宇宙文档转换").tag(Optional("doc_convert"))
                                        Text("全能文档合并").tag(Optional("merge_docs"))
                                    }
                                    Section(header: Text("剪辑增强")) {
                                        Text("XML版本降级").tag(Optional("xml_downgrade"))
                                        Text("库缓存清理").tag(Optional("clean_cache"))
                                        Text("音频标准化").tag(Optional("normalize_audio"))
                                        Text("万能图像处理").tag(Optional("image_process"))
                                        Text("全网媒体解析").tag(Optional("media_download"))
                                    }
                                    Section(header: Text("生产力")) {
                                        Text("屏幕取色").tag(Optional("pick_color"))
                                        Text("屏幕防休眠").tag(Optional("anti_sleep"))
                                        Text("JSON格式化").tag(Optional("json_format"))
                                        Text("科学计算器").tag(Optional("science_calc"))
                                        Text("单位换算").tag(Optional("unit_calc"))
                                        Text("汇率系统").tag(Optional("currency_calc"))
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                                
                                ShortcutRecorderView(hotkey: $settings.customHotkeys[index])
                            }
                        }
                        if index < 4 { Divider().padding(.leading, 56) }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)

                VStack(spacing: 0) {
                    SettingsRow(icon: "folder.fill", title: lang.t("set_save_path"), subtitle: settings.savePath, color: .orange) {
                        Button(action: { settings.selectSaveDirectory() }) {
                            Text("更改").font(.caption).fontWeight(.bold).padding(.horizontal, 12).padding(.vertical, 6).background(Color.accentColor).foregroundColor(.white).cornerRadius(6)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    Divider().padding(.leading, 56)
                    SettingsRow(icon: "globe", title: lang.t("set_language"), subtitle: lang.t("set_lang_desc"), color: .purple) {
                        Picker("", selection: $lang.currentLanguage) {
                            Text("中文").tag(AppLanguage.zh)
                            Text("English").tag(AppLanguage.en)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let content: Content
    
    init(icon: String, title: String, subtitle: String, color: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon; self.title = title; self.subtitle = subtitle; self.color = color; self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .medium))
                Text(subtitle).font(.caption).foregroundColor(.secondary).lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            content
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}
