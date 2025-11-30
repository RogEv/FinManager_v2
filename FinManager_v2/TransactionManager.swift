//
//  TransactionManager.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation

class TransactionManager: ObservableObject {
    @Published var transactions: [FinancialTransaction] = []
    @Published var monthlySummary: MonthlySummary?
    
    let analyticsEngine: AnalyticsEngine
    let uiManager: UIManager
    
    // Пустой инициализатор для @StateObject
    init() {
        self.uiManager = UIManager()
        self.analyticsEngine = AnalyticsEngine()
    }
    
    // Полный инициализатор для dependency injection
    init(analyticsEngine: AnalyticsEngine, uiManager: UIManager) {
        self.analyticsEngine = analyticsEngine
        self.uiManager = uiManager
    }
    
    func addTransaction(_ transaction: FinancialTransaction) {
        // Добавляем транзакцию на главном потоке
        DispatchQueue.main.async {
            self.transactions.append(transaction)
            self.updateAnalytics()
            self.uiManager.triggerHaptic(.light)
            
            print("✅ Добавлена транзакция: \(transaction.description) - \(transaction.amount) BYN")
            print("📊 Транзакций всего: \(self.transactions.count)")
            
            // Запускаем аналитику в фоне, но обновления будут на главном потоке
            DispatchQueue.global(qos: .userInitiated).async {
                self.updateAllAnalytics()
            }
        }
    }
    
    func processSMSMessages(_ messages: [String]) {
        let parser = SMSParser()
        
        for message in messages {
            if let transaction = parser.parseSMS(message) {
                addTransaction(transaction)
            }
        }
        updateAnalytics()
        updateAllAnalytics()
       
    }
    
    private func updateAllAnalytics() {
        print("🔄 Начинаем полное обновление аналитики...")
        
        // Все обновления должны быть на главном потоке
        DispatchQueue.main.async {
            self.updateAnalytics()
            
            let trendsBefore = self.analyticsEngine.spendingTrends.count
            self.analyticsEngine.analyzeSpendingTrends(transactions: self.transactions)
            let trendsAfter = self.analyticsEngine.spendingTrends.count
            
            self.analyticsEngine.checkBudgetLimits(transactions: self.transactions)
            self.analyticsEngine.generateFinancialInsights(transactions: self.transactions)
            
            print("📈 Аналитика обновлена:")
            print("   - Тренды: \(trendsBefore) → \(trendsAfter)")
            print("   - Инсайты: \(self.analyticsEngine.financialInsights.count)")
            print("   - Алерты: \(self.analyticsEngine.budgetAlerts.count)")
            print("   - Сводка: \(self.monthlySummary?.income ?? 0)/\(self.monthlySummary?.expenses ?? 0)")
            
            // Уведомляем об изменениях (уже на главном потоке)
            self.objectWillChange.send()
        }
    }
        
    private func updateAnalytics() {
        // Этот метод должен работать только на главном потоке
        assert(Thread.isMainThread, "updateAnalytics must be called on main thread")
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let monthlyTransactions = transactions.filter { transaction in
            let transactionMonth = Calendar.current.component(.month, from: transaction.date)
            let transactionYear = Calendar.current.component(.year, from: transaction.date)
            return transactionMonth == currentMonth && transactionYear == currentYear
        }
        
        let income = monthlyTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expenses = monthlyTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        monthlySummary = MonthlySummary(
            income: income,
            expenses: expenses,
            savings: income - expenses
        )
        
        print("📊 Сводка обновлена: доходы = \(income), расходы = \(expenses)")
    }
    
    func getCategoryBreakdown() -> [CategoryBreakdown] {
        let expenseTransactions = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenseTransactions, by: { $0.category })
        
        return grouped.map { category, transactions in
            let total = transactions.reduce(0) { $0 + $1.amount }
            return CategoryBreakdown(category: category, amount: total)
        }
    }
}

extension TransactionManager {
    func performMainThreadUpdate(_ update: @escaping () -> Void) {
        if Thread.isMainThread {
            update()
        } else {
            DispatchQueue.main.async {
                update()
            }
        }
    }
    
    func refreshAllData() {
        performMainThreadUpdate {
            self.updateAnalytics()
            self.objectWillChange.send()
            
            // Аналитику запускаем в фоне
            DispatchQueue.global(qos: .userInitiated).async {
                self.analyticsEngine.analyzeSpendingTrends(transactions: self.transactions)
                self.analyticsEngine.checkBudgetLimits(transactions: self.transactions)
                self.analyticsEngine.generateFinancialInsights(transactions: self.transactions)
            }
        }
    }
}

extension TransactionManager {
    
    func importMultipleSMS(_ messages: [String]) -> ImportResult {
        let parser = SMSParser()
        var importedCount = 0
        var failedCount = 0
        var errors: [String] = []
        
        // Собираем все транзакции
        var newTransactions: [FinancialTransaction] = []
        
        for message in messages {
            if let transaction = parser.parseSMS(message) {
                if !isDuplicateTransaction(transaction) {
                    newTransactions.append(transaction)
                    importedCount += 1
                } else {
                    failedCount += 1
                    errors.append("Дубликат: \(transaction.description)")
                }
            } else {
                failedCount += 1
                errors.append("Не распознано: \(message.prefix(30))...")
            }
        }
        
        // Добавляем все транзакции на главном потоке
        DispatchQueue.main.async {
            self.transactions.append(contentsOf: newTransactions)
            self.updateAnalytics()
            
            print("✅ Импортировано \(importedCount) транзакций")
            
            // Запускаем аналитику в фоне
            DispatchQueue.global(qos: .userInitiated).async {
                self.updateAllAnalytics()
            }
        }
        
        return ImportResult(
            importedCount: importedCount,
            failedCount: failedCount,
            errors: errors
        )
    }
    
    private func isDuplicateTransaction(_ transaction: FinancialTransaction) -> Bool {
        return transactions.contains { existing in
            existing.amount == transaction.amount &&
            existing.description == transaction.description &&
            Calendar.current.isDate(existing.date, inSameDayAs: transaction.date)
        }
    }
}

extension TransactionManager {
    
    func addManualTransaction(
        amount: Double,
        category: TransactionCategory,
        date: Date,
        description: String,
        type: TransactionType
    ) -> Bool {
        guard amount > 0 else { return false }
        
        let transaction = FinancialTransaction(
            amount: amount,
            category: category,
            date: date,
            description: description,
            type: type
        )
        
        // ИСПОЛЬЗУЕМ addTransaction вместо прямого добавления
        addTransaction(transaction)
        return true
    }
}

struct ImportResult {
    let importedCount: Int
    let failedCount: Int
    let errors: [String]
}


struct MonthlySummary {
    let income: Double
    let expenses: Double
    let savings: Double
}

struct CategoryBreakdown: Identifiable {
    let id = UUID() // Добавляем идентификатор
    let category: TransactionCategory
    let amount: Double
}
