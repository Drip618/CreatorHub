import SwiftUI

struct SmartCalculatorView: View {
    @State private var input: String = ""
    @State private var result: String = "0"
    @State private var selectedTab = 0 // 0: Calc, 1: Unit, 2: Currency
    
    // Currency Data
    let rates = ["USD": 1.0, "CNY": 7.23, "EUR": 0.92, "JPY": 155.0, "HKD": 7.82]
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "CNY"
    
    // Unit Data
    let units = ["长度 (m -> ft)": 3.28084, "重量 (kg -> lb)": 2.20462, "面积 (m² -> ft²)": 10.7639]
    @State private var selectedUnit = "长度 (m -> ft)"
    
    let buttons = [
        ["7", "8", "9", "/"],
        ["4", "5", "6", "*"],
        ["1", "2", "3", "-"],
        ["0", ".", "C", "+"],
        ["sin", "cos", "tan", "="]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("科学计算").tag(0)
                Text("单位换算").tag(1)
                Text("全球汇率").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            VStack(spacing: 15) {
                // Display Area
                VStack(alignment: .trailing, spacing: 5) {
                    TextField("输入...", text: $input)
                        .textFieldStyle(.plain)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .onChange(of: input) { _ in autoCalculate() }
                    
                    Text(result)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
                
                if selectedTab == 0 {
                    numpadGrid
                } else if selectedTab == 1 {
                    unitControls
                } else {
                    currencyControls
                }
            }
            .padding()
            
            Button("复制结果") {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(result, forType: .string)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .frame(width: 400, height: 550)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
    }
    
    var numpadGrid: some View {
        VStack(spacing: 10) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { label in
                        Button(action: { buttonPressed(label) }) {
                            Text(label)
                                .font(.system(size: 18, weight: .medium))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                        .buttonStyle(.bordered)
                        .tint(isOperator(label) ? .orange : .primary)
                    }
                }
            }
        }
    }
    
    var unitControls: some View {
        VStack(spacing: 20) {
            Picker("换算类型", selection: $selectedUnit) {
                ForEach(units.keys.sorted(), id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
            
            Text("支持键盘直接输入数值")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    var currencyControls: some View {
        VStack(spacing: 20) {
            HStack {
                Picker("", selection: $fromCurrency) {
                    ForEach(rates.keys.sorted(), id: \.self) { Text($0) }
                }
                Image(systemName: "arrow.right")
                Picker("", selection: $toCurrency) {
                    ForEach(rates.keys.sorted(), id: \.self) { Text($0) }
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    func buttonPressed(_ label: String) {
        if label == "C" {
            input = ""
            result = "0"
        } else if label == "=" {
            calculateFinal()
        } else if ["sin", "cos", "tan"].contains(label) {
            input += "\(label)("
        } else {
            input += label
        }
    }
    
    func isOperator(_ label: String) -> Bool {
        return ["/", "*", "-", "+", "=", "sin", "cos", "tan"].contains(label)
    }
    
    func autoCalculate() {
        if selectedTab == 1 { convertUnit() }
        else if selectedTab == 2 { convertCurrency() }
        else {
            // Optional: Preview calculation
        }
    }
    
    func calculateFinal() {
        let expressionStr = input.replacingOccurrences(of: "sin", with: "sin")
            .replacingOccurrences(of: "cos", with: "cos")
            .replacingOccurrences(of: "tan", with: "tan")
        
        let expression = NSExpression(format: expressionStr)
        if let val = expression.expressionValue(with: nil, context: nil) as? NSNumber {
            result = "\(val.doubleValue)"
        } else {
            result = "Error"
        }
    }
    
    func convertUnit() {
        guard let val = Double(input) else { result = "0"; return }
        if let factor = units[selectedUnit] {
            result = String(format: "%.4f", val * factor)
        }
    }
    
    func convertCurrency() {
        guard let val = Double(input),
              let fromRate = rates[fromCurrency],
              let toRate = rates[toCurrency] else { result = "0"; return }
        let base = val / fromRate
        result = String(format: "%.2f", base * toRate)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
