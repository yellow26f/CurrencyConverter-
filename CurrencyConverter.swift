import Foundation

struct ExchangeRate {
    let from: String
    let to: String
    let rate: Double
    let timestamp: Date
}

class CurrencyConverter {
    private var rates: [String: ExchangeRate] = [:]
    private let cacheFile = "rates_cache.json"
    
    init() {
        loadCache()
    }
    
    func addRate(from: String, to: String, rate: Double) {
        let key = "\(from)_\(to)"
        rates[key] = ExchangeRate(from: from, to: to, rate: rate, timestamp: Date())
        saveCache()
    }
    
    func convert(amount: Double, from: String, to: String) -> Double? {
        if from == to {
            return amount
        }
        
        let key = "\(from)_\(to)"
        if let rate = rates[key] {
            return amount * rate.rate
        }
        
        let reverseKey = "\(to)_\(from)"
        if let rate = rates[reverseKey] {
            return amount / rate.rate
        }
        
        return nil
    }
    
    func listRates() {
        if rates.isEmpty {
            print("No exchange rates available")
            return
        }
        
        print("\n=== Exchange Rates ===")
        for (_, rate) in rates {
            print("\(rate.from) -> \(rate.to): \(rate.rate)")
        }
    }
    
    func saveCache() {
        var data: [[String: Any]] = []
        
        for (_, rate) in rates {
            data.append([
                "from": rate.from,
                "to": rate.to,
                "rate": rate.rate,
                "timestamp": rate.timestamp.timeIntervalSince1970
            ])
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            try jsonData.write(to: URL(fileURLWithPath: cacheFile))
        } catch {
            print("Error saving cache: \(error)")
        }
    }
    
    func loadCache() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: cacheFile)) else {
            return
        }
        
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for item in jsonArray {
                    if let from = item["from"] as? String,
                       let to = item["to"] as? String,
                       let rate = item["rate"] as? Double,
                       let timestamp = item["timestamp"] as? TimeInterval {
                        
                        let key = "\(from)_\(to)"
                        rates[key] = ExchangeRate(
                            from: from,
                            to: to,
                            rate: rate,
                            timestamp: Date(timeIntervalSince1970: timestamp)
                        )
                    }
                }
            }
        } catch {
            print("Error loading cache: \(error)")
        }
    }
    
    func compareRates(amount: Double, from: String, targets: [String]) {
        print("\n=== Currency Comparison ===")
        print("Amount: \(amount) \(from)\n")
        
        for target in targets {
            if let converted = convert(amount: amount, from: from, to: target) {
                print("\(target): \(String(format: "%.2f", converted))")
            } else {
                print("\(target): Rate not available")
            }
        }
    }
}

class ConversionHistory {
    struct Conversion {
        let amount: Double
        let from: String
        let to: String
        let result: Double
        let timestamp: Date
    }
    
    private var history: [Conversion] = []
    private let maxHistory = 50
    
    func addConversion(amount: Double, from: String, to: String, result: Double) {
        let conversion = Conversion(
            amount: amount,
            from: from,
            to: to,
            result: result,
            timestamp: Date()
        )
        history.append(conversion)
        
        if history.count > maxHistory {
            history.removeFirst()
        }
    }
    
    func viewHistory() {
        if history.isEmpty {
            print("No conversion history")
            return
        }
        
        print("\n=== Conversion History ===")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for (index, conv) in history.enumerated().suffix(10) {
            print("\(index + 1). \(conv.amount) \(conv.from) = \(String(format: "%.2f", conv.result)) \(conv.to)")
            print("   \(formatter.string(from: conv.timestamp))")
        }
    }
    
    func clearHistory() {
        history.removeAll()
        print("History cleared")
    }
}

func readLine(prompt: String) -> String {
    print(prompt, terminator: "")
    return readLine() ?? ""
}

func main() {
    let converter = CurrencyConverter()
    let history = ConversionHistory()
    
    converter.addRate(from: "USD", to: "EUR", rate: 0.92)
    converter.addRate(from: "USD", to: "GBP", rate: 0.79)
    converter.addRate(from: "USD", to: "JPY", rate: 149.50)
    converter.addRate(from: "EUR", to: "GBP", rate: 0.86)
    
    while true {
        print("\n=== Currency Converter ===")
        print("1. Convert Currency")
        print("2. Add Exchange Rate")
        print("3. List All Rates")
        print("4. Compare Rates")
        print("5. View History")
        print("6. Clear History")
        print("7. Exit")
        
        let choice = readLine(prompt: "\nEnter choice: ")
        
        switch choice {
        case "1":
            let amountStr = readLine(prompt: "Amount: ")
            guard let amount = Double(amountStr) else {
                print("Invalid amount")
                continue
            }
            
            let from = readLine(prompt: "From currency (e.g., USD): ").uppercased()
            let to = readLine(prompt: "To currency (e.g., EUR): ").uppercased()
            
            if let result = converter.convert(amount: amount, from: from, to: to) {
                print(String(format: "\n%.2f %@ = %.2f %@", amount, from, result, to))
                history.addConversion(amount: amount, from: from, to: to, result: result)
            } else {
                print("Exchange rate not available")
            }
            
        case "2":
            let from = readLine(prompt: "From currency: ").uppercased()
            let to = readLine(prompt: "To currency: ").uppercased()
            let rateStr = readLine(prompt: "Exchange rate: ")
            
            if let rate = Double(rateStr) {
                converter.addRate(from: from, to: to, rate: rate)
                print("Rate added")
            } else {
                print("Invalid rate")
            }
            
        case "3":
            converter.listRates()
            
        case "4":
            let amountStr = readLine(prompt: "Amount: ")
            guard let amount = Double(amountStr) else {
                print("Invalid amount")
                continue
            }
            
            let from = readLine(prompt: "From currency: ").uppercased()
            let targetsStr = readLine(prompt: "Target currencies (comma-separated): ")
            let targets = targetsStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
            
            converter.compareRates(amount: amount, from: from, targets: targets)
            
        case "5":
            history.viewHistory()
            
        case "6":
            history.clearHistory()
            
        case "7":
            print("Goodbye!")
            return
            
        default:
            print("Invalid choice")
        }
    }
}

main()
