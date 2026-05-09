import SwiftUI

struct SmartCalculatorView: View {
    @State private var input: String = ""
    @State private var result: String = "0"
    @State private var selectedTab: Int
    
    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    @State private var selectedUnit = "len"
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "CNY"
    
    let opColor = Color.orange
    let numColor = Color.secondary.opacity(0.15)
    let funcColor = Color.secondary.opacity(0.35)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(toolTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { NSApp.keyWindow?.close() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            
            // Result Display Area (Premium Style)
            VStack(alignment: .trailing, spacing: 5) {
                if selectedTab == 0 {
                    Text(input.isEmpty ? " " : input)
                        .font(.system(size: 18, weight: .light, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(result)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(20)
            .padding(.horizontal, 20)
            
            // Interface Content
            VStack {
                if selectedTab == 0 {
                    calculatorInterface.transition(.move(edge: .bottom).combined(with: .opacity))
                } else if selectedTab == 1 {
                    unitInterface.transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    currencyInterface.transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Bottom Action
            Button(action: copyResult) {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                    Text("复制结果 (Copy Result)")
                }
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .frame(width: 480)
        .background(CalcVisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
    }
    
    var toolTitle: String {
        switch selectedTab {
        case 0: return "科学计算器"
        case 1: return "万能单位换算"
        case 2: return "全球实时汇率"
        default: return ""
        }
    }
    
    var calculatorInterface: some View {
        HStack(spacing: 12) {
            VStack(spacing: 12) {
                ForEach(["sin", "cos", "tan", "log", "√", "π", "e", "^"], id: \.self) { label in
                    CalcButton(label: label, color: funcColor) { handlePress(label) }
                }
            }
            .frame(width: 80)
            
            VStack(spacing: 12) {
                ForEach([
                    ["AC", "±", "%", "/"],
                    ["7", "8", "9", "*"],
                    ["4", "5", "6", "-"],
                    ["1", "2", "3", "+"],
                    ["0", ".", "Del", "="]
                ], id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { label in
                            CalcButton(label: label, color: isOperator(label) ? opColor : (isFunc(label) ? funcColor : numColor)) {
                                handlePress(label)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    var unitInterface: some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Text("输入原始数值").font(.headline).foregroundColor(.secondary)
                TextField("请输入数字...", text: $input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .onChange(of: input) { _ in autoConvert() }
            }
            .padding(30)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(20)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("选择换算类型").font(.headline).foregroundColor(.secondary)
                Picker("", selection: $selectedUnit) {
                    Text("📏 长度").tag("len")
                    Text("⚖️ 重量").tag("weight")
                    Text("📐 面积").tag("area")
                    Text("🧪 体积").tag("vol")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.horizontal, 30)
    }
    
    var currencyInterface: some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Text("基础金额").font(.headline).foregroundColor(.secondary)
                TextField("输入金额...", text: $input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .onChange(of: input) { _ in autoConvert() }
            }
            .padding(30)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(20)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("从 (From)").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: $fromCurrency) {
                        Text("USD 🇺🇸").tag("USD")
                        Text("CNY 🇨🇳").tag("CNY")
                        Text("EUR 🇪🇺").tag("EUR")
                        Text("JPY 🇯🇵").tag("JPY")
                    }
                }
                Image(systemName: "arrow.right.circle.fill").font(.largeTitle).foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text("到 (To)").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: $toCurrency) {
                        Text("CNY 🇨🇳").tag("CNY")
                        Text("USD 🇺🇸").tag("USD")
                        Text("EUR 🇪🇺").tag("EUR")
                        Text("JPY 🇯🇵").tag("JPY")
                    }
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(Color.primary.opacity(0.05))
            .cornerRadius(15)
        }
        .padding(.horizontal, 30)
    }
    
    func handlePress(_ label: String) {
        if label == "AC" { input = ""; result = "0" }
        else if label == "Del" { if !input.isEmpty { input.removeLast() } }
        else if label == "=" { calculateResult() }
        else if ["sin", "cos", "tan", "log", "√"].contains(label) { input += label + "(" }
        else { input += label }
        autoConvert()
    }
    
    func calculateResult() {
        if input.isEmpty { return }
        let formula = input.replacingOccurrences(of: "√", with: "sqrt")
            .replacingOccurrences(of: "π", with: "\(Double.pi)")
            .replacingOccurrences(of: "e", with: "\(M_E)")
            .replacingOccurrences(of: "log", with: "log10")
        let expression = NSExpression(format: formula)
        if let val = expression.expressionValue(with: nil, context: nil) as? NSNumber { result = formatNumber(val.doubleValue) }
        else { result = "格式错误" }
    }
    
    func autoConvert() {
        guard let val = Double(input) else { return }
        if selectedTab == 1 {
            let factors: [String: Double] = ["len": 3.28084, "weight": 2.20462, "area": 10.7639, "vol": 0.264172]
            if let factor = factors[selectedUnit] { result = formatNumber(val * factor) }
        } else if selectedTab == 2 {
            let rates: [String: Double] = ["USD": 1.0, "CNY": 7.23, "EUR": 0.92, "JPY": 155.0]
            if let from = rates[fromCurrency], let to = rates[toCurrency] { result = formatNumber((val / from) * to) }
        }
    }
    
    func formatNumber(_ d: Double) -> String {
        let formatter = NumberFormatter(); formatter.minimumFractionDigits = 0; formatter.maximumFractionDigits = 4; formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: d)) ?? "\(d)"
    }
    
    func copyResult() { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(result, forType: .string) }
    func isOperator(_ s: String) -> Bool { ["/", "*", "-", "+", "="].contains(s) }
    func isFunc(_ s: String) -> Bool { ["AC", "±", "%", "Del"].contains(s) }
}

struct CalcButton: View {
    let label: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color).foregroundColor(color == .orange ? .white : .primary)
                .cornerRadius(15).shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }.buttonStyle(.plain)
    }
}

struct CalcVisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material; let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView { let view = NSVisualEffectView(); view.material = material; view.blendingMode = blendingMode; view.state = .active; return view }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
