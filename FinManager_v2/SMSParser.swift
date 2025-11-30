//
//  SMSParser.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation

class SMSParser {
    private let categorizer: TransactionCategorizer
    
    init() {
        self.categorizer = TransactionCategorizer()
    }
    
    func parseSMS(_ message: String) -> FinancialTransaction? {
        let cleanedMessage = preprocessMessage(message)
        
        // Пропускаем служебные SMS (3D-Secure коды и т.д.)
        if shouldSkipMessage(cleanedMessage) {
            return nil
        }
        
        // Парсим в зависимости от формата
        if cleanedMessage.contains("Karta 4***") {
            return parseKartaFormat(cleanedMessage)
        } else if cleanedMessage.contains("<#>") {
            return parseHashFormat(cleanedMessage)
        } else if cleanedMessage.contains("Na vashu kartu zachisleno") {
            return parseIncomeFormat(cleanedMessage)
        } else if cleanedMessage.contains("Priorbank") {
            return parsePriorbankFormat(cleanedMessage)
        } else {
            return parseGenericFormat(cleanedMessage)
        }
    }
    
    private func preprocessMessage(_ message: String) -> String {
        return message
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "§", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func shouldSkipMessage(_ message: String) -> Bool {
        let skipPatterns = [
            "3D-Secure kod=",
            "M-code:",
            "Spravka:",
            "VhGfTg0y6/D"
        ]
        
        return skipPatterns.contains { message.contains($0) }
    }
    
    // Формат: Karta 4***9392 01-11-25 13:42:20. Oplata 67.95 BYN. BLR LAMODA.BY. Dostupno: 1298.77 BYN. Tel. 7299090
    private func parseKartaFormat(_ message: String) -> FinancialTransaction? {
        guard let amount = extractAmount(from: message),
              let date = extractDate(from: message) else {
            return nil
        }
        
        let description = extractDescription(from: message)
        let type = determineTransactionType(from: message, amount: amount)
        let category = categorizer.categorize(message: message)
        
        return FinancialTransaction(
            amount: amount,
            category: category,
            date: date,
            description: description,
            type: type
        )
    }
    
    // Формат: <#> 02/11 17:34. Platezh s DK9392, schet platezha 33698513. Summa 17.00 BYN. M-code:745434. Tel. 7299090 VhGfTg0y6/D
    private func parseHashFormat(_ message: String) -> FinancialTransaction? {
        guard let amount = extractAmount(from: message),
              let date = extractDate(from: message) else {
            return nil
        }
        
        let description = "Mobile Payment"
        let type: TransactionType = .expense
        let category = categorizer.categorize(message: message)
        
        return FinancialTransaction(
            amount: amount,
            category: category,
            date: date,
            description: description,
            type: type
        )
    }
    
    // Формат: 10/11 14:04. Na vashu kartu zachisleno 154.00 BYN. Dostupnaja summa: 403.92 BYN. Tel. 7299090
    private func parseIncomeFormat(_ message: String) -> FinancialTransaction? {
        guard let amount = extractAmount(from: message),
              let date = extractDate(from: message) else {
            return nil
        }
        
        return FinancialTransaction(
            amount: amount,
            category: .salary,
            date: date,
            description: "Зачисление на карту",
            type: .income
        )
    }
    
    // Формат: Priorbank. 3D-Secure kod= 912272. Summa platezha 67.95 BYN. Karta ***9392. Spravka: 487
    private func parsePriorbankFormat(_ message: String) -> FinancialTransaction? {
        guard let amount = extractAmount(from: message) else { return nil }
        
        return FinancialTransaction(
            amount: amount,
            category: .other,
            date: Date(),
            description: "Онлайн платеж",
            type: .expense
        )
    }
    
    private func parseGenericFormat(_ message: String) -> FinancialTransaction? {
        guard let amount = extractAmount(from: message) else { return nil }
        
        let date = extractDate(from: message) ?? Date()
        let description = extractDescription(from: message)
        let type = determineTransactionType(from: message, amount: amount)
        let category = categorizer.categorize(message: message)
        
        return FinancialTransaction(
            amount: amount,
            category: category,
            date: date,
            description: description,
            type: type
        )
    }
    
    private func extractAmount(from text: String) -> Double? {
        let patterns = [
            "Oplata\\s+([0-9]+[.,][0-9]+)\\s+BYN",
            "Perevod\\s+([0-9]+[.,][0-9]+)\\s+BYN",
            "Nalichnye\\s+[\\w\\s]+\\s+([0-9]+[.,][0-9]+)\\s+BYN",
            "Summa\\s+([0-9]+[.,][0-9]+)\\s+BYN",
            "Zachisleno\\s+([0-9]+[.,][0-9]+)\\s+BYN",
            "Vybrano\\s+[\\w\\s]+\\s+([0-9]+[.,][0-9]+)\\s+BYN",
            "([0-9]+[.,][0-9]+)\\s+BYN[^0-9]", // Общий паттерн для сумм в BYN
            "Oplata\\s+([0-9]+[.,][0-9]+)\\s+USD",
            "([0-9]+[.,][0-9]+)\\s+USD"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let amountRange = Range(match.range(at: 1), in: text)!
                    var amountString = String(text[amountRange])
                    
                    amountString = amountString.replacingOccurrences(of: ",", with: ".")
                    return Double(amountString)
                }
            }
        }
        
        return nil
    }
    
    private func extractDate(from text: String) -> Date? {
        let dateFormats = [
            "dd-MM-yy HH:mm:ss",
            "dd/MM/yy HH:mm",
            "dd/MM HH:mm",
            "dd-MM-yy",
            "dd/MM/yy"
        ]
        
        let datePatterns = [
            "\\b(\\d{1,2}[-/]\\d{1,2}[-/]?\\d{0,4})\\s+(\\d{1,2}:\\d{2}:?\\d{0,2})\\b",
            "\\b(\\d{1,2}[-/]\\d{1,2})\\s+(\\d{1,2}:\\d{2})\\b"
        ]
        
        for pattern in datePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                var dateString = (text as NSString).substring(with: match.range)
                
                // Нормализуем разделители
                dateString = dateString.replacingOccurrences(of: "/", with: "-")
                
                for format in dateFormats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "ru_BY")
                    
                    if let date = formatter.date(from: dateString) {
                        // Если год не указан, добавляем текущий
                        if format == "dd/MM HH:mm" {
                            let calendar = Calendar.current
                            let currentYear = calendar.component(.year, from: Date())
                            var components = calendar.dateComponents([.day, .month, .hour, .minute], from: date)
                            components.year = currentYear
                            return calendar.date(from: components)
                        }
                        return date
                    }
                }
            }
        }
        
        return Date()
    }
    
    private func extractDescription(from text: String) -> String {
        // Паттерны для извлечения описания
        let patterns = [
            "BYN\\.\\s*([^.]+)\\.", // После "BYN." до точки
            "BYN\\.\\s*([^.]*\\.[^.]*\\.)", // Для случаев с двумя точками
            "BLR\\s+([^.]+)\\.", // После "BLR" до точки
            "USA\\s+([^.]+)\\.", // После "USA" до точки
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let descriptionRange = Range(match.range(at: 1), in: text)!
                    var description = String(text[descriptionRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "\"", with: "")
                    
                    if !description.isEmpty {
                        return description
                    }
                }
            }
        }
        
        // Альтернативный метод для формата с <#>
        if text.contains("Platezh s DK") {
            return "Мобильный банк"
        } else if text.contains("Zachisleno") {
            return "Зачисление на карту"
        }
        
        return "Неизвестная операция"
    }
    
    private func determineTransactionType(from text: String, amount: Double) -> TransactionType {
        let lowercasedText = text.lowercased()
        
        let incomeKeywords = [
            "zachisleno", "postuplenie", "popolnenie", "na vashu kartu",
            "зачислено", "поступление", "пополнение"
        ]
        
        let expenseKeywords = [
            "oplata", "spisanie", "platezh", "perevod", "nalichnye", "snyatie",
            "оплата", "списание", "платеж", "перевод", "наличные", "снятие",
            "vybrano"
        ]
        
        if incomeKeywords.contains(where: lowercasedText.contains) {
            return .income
        } else if expenseKeywords.contains(where: lowercasedText.contains) {
            return .expense
        }
        
        return .expense
    }
}
