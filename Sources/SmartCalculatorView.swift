import SwiftUI

struct SmartCalculatorView: View {
    @State private var input: String = ""
    @State private var result: String = "0"
    @State private var selectedTab = 0 // 0: Calc, 1: Unit, 2: Currency
    
    // Currency Data (Mock for offline/simplicity, can be updated with API)
    let rates = ["USD": 1.0, "CNY": 7.23, "EUR": 0.92, "JPY": 155.0, "HKD": 7.82]
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "CNY"
    
    // Unit Data
    let units = ["长度 (m -> ft)": 3.28084, "重量 (kg -> lb)": 2.20462, "面积 (m² -> ft²)": 10.7639]
    @State private var selectedUnit = "长度 (m -> ft)"
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("科学计算").tag(0)
                Text("单位换算").tag(1)
                Text("全球汇率").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            VStack(spacing: 20) {
                if selectedTab == 0 {
                    calculatorBody
                } else if selectedTab == 1 {
                    unitBody
                } else {
                    currencyBody
                }
                
                Divider()
                
                VStack(alignment: .trailing) {
                    Text("结果 (Result)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
            
            Spacer()
            
            Button("复制结果") {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(result, forType: .string)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .frame(width: 400, height: 500)
    }
    
    var calculatorBody: some View {
        VStack {
            TextField("输入表达式 (如: 1.2 * (5 + 3) / sin(0.5))", text: $input)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onChange(of: input) { _ in calculate() }
            
            Text("支持: +, -, *, /, sin, cos, tan, log, sqrt, pi")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    var unitBody: some View {
        VStack(spacing: 15) {
            Picker("换算类型", selection: $selectedUnit) {
                ForEach(units.keys.sorted(), id: \.self) { Text($0) }
            }
            TextField("输入数值", text: $input)
                .textFieldStyle(.roundedBorder)
                .onChange(of: input) { _ in convertUnit() }
        }
    }
    
    var currencyBody: some View {
        VStack(spacing: 15) {
            HStack {
                Picker("从", selection: $fromCurrency) {
                    ForEach(rates.keys.sorted(), id: \.self) { Text($0) }
                }
                Image(systemName: "arrow.right")
                Picker("到", selection: $toCurrency) {
                    ForEach(rates.keys.sorted(), id: \.self) { Text($0) }
                }
            }
            TextField("输入金额", text: $input)
                .textFieldStyle(.roundedBorder)
                .onChange(of: input) { _ in convertCurrency() }
        }
    }
    
    func calculate() {
        let expression = NSExpression(format: input.replacingOccurrences(of: "pi", with: "\(Double.pi)"))
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
