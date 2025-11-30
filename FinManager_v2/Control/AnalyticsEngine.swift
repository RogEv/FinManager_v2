import Foundation
import SwiftUI

class AnalyticsEngine: ObservableObject {
    @Published var spendingTrends: [SpendingTrend] = []
    @Published var budgetAlerts: [BudgetAlert] = []
    @Published var financialInsights: [FinancialInsight] = []
    
    private let budgetLimits: [TransactionCategory: Double] = [
        .food: 20000,
        .transportation: 10000,
        .shopping: 15000,
        .entertainment: 8000,
        .bills: 25000,
        .other: 5000
    ]
    
    @discardableResult
    func analyzeSpendingTrends(transactions: [FinancialTransaction]) -> [SpendingTrend] {
        let trends = performTrendsAnalysis(transactions: transactions)
        
        DispatchQueue.main.async {
            self.spendingTrends = trends
        }
        
        return trends
    }
    
    @discardableResult
    func checkBudgetLimits(transactions: [FinancialTransaction]) -> [BudgetAlert] {
        let alerts = performBudgetAnalysis(transactions: transactions)
        
        DispatchQueue.main.async {
            self.budgetAlerts = alerts
        }
        
        return alerts
    }
    
    @discardableResult
    func generateFinancialInsights(transactions: [FinancialTransaction]) -> [FinancialInsight] {
        let insights = performInsightsAnalysis(transactions: transactions)
        
        DispatchQueue.main.async {
            self.financialInsights = insights
        }
        
        return insights
    }
    
    // MARK: - Private Methods
    
    private func performTrendsAnalysis(transactions: [FinancialTransaction]) -> [SpendingTrend] {
        let calendar = Calendar.current
        var monthlySpending: [Date: [FinancialTransaction]] = [:]
        
        for transaction in transactions {
            let month = calendar.date(from: calendar.dateComponents([.year, .month], from: transaction.date))!
            if monthlySpending[month] == nil {
                monthlySpending[month] = []
            }
            monthlySpending[month]?.append(transaction)
        }
        
        var trends: [SpendingTrend] = []
        let sortedMonths = monthlySpending.keys.sorted()
        
        for (index, month) in sortedMonths.enumerated() {
            guard let monthlyTransactions = monthlySpending[month] else { continue }
            
            let totalExpenses = monthlyTransactions
                .filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount }
            
            let totalIncome = monthlyTransactions
                .filter { $0.type == .income }
                .reduce(0) { $0 + $1.amount }
            
            var changePercentage: Double? = nil
            if index > 0 {
                let previousMonth = sortedMonths[index - 1]
                if let previousTransactions = monthlySpending[previousMonth] {
                    let previousExpenses = previousTransactions
                        .filter { $0.type == .expense }
                        .reduce(0) { $0 + $1.amount }
                    
                    if previousExpenses > 0 {
                        changePercentage = ((totalExpenses - previousExpenses) / previousExpenses) * 100
                    }
                }
            }
            
            let categoryBreakdown = calculateCategoryBreakdown(transactions: monthlyTransactions)
            
            let trend = SpendingTrend(
                period: month,
                totalExpenses: totalExpenses,
                totalIncome: totalIncome,
                changePercentage: changePercentage,
                categoryBreakdown: categoryBreakdown
            )
            
            trends.append(trend)
        }
        
        return trends
    }
    
    private func performBudgetAnalysis(transactions: [FinancialTransaction]) -> [BudgetAlert] {
        var alerts: [BudgetAlert] = []
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        let currentMonthTransactions = transactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transactionMonth == currentMonth && transactionYear == currentYear && transaction.type == .expense
        }
        
        let expensesByCategory = Dictionary(grouping: currentMonthTransactions, by: { $0.category })
        
        for (category, categoryTransactions) in expensesByCategory {
            guard let budgetLimit = budgetLimits[category] else { continue }
            
            let totalSpent = categoryTransactions.reduce(0) { $0 + $1.amount }
            let percentage = (totalSpent / budgetLimit) * 100
            
            if percentage >= 80 {
                let alertType: BudgetAlert.AlertType = percentage >= 100 ? .exceeded : .warning
                
                let alert = BudgetAlert(
                    category: category,
                    spentAmount: totalSpent,
                    budgetLimit: budgetLimit,
                    percentage: percentage,
                    alertType: alertType
                )
                alerts.append(alert)
            }
        }
        
        return alerts.sorted { $0.percentage > $1.percentage }
    }
    private func safePercentage(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        guard !value.isNaN else { return 0 }
        guard !value.isInfinite else { return 0 }
        
        return Int(value.rounded())
    }

    private func safeInt(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        guard !value.isNaN else { return 0 }
        guard !value.isInfinite else { return 0 }
        
        return Int(value.rounded())
    }
    
    private func performInsightsAnalysis(transactions: [FinancialTransaction]) -> [FinancialInsight] {
        var insights: [FinancialInsight] = []
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        let currentMonthTransactions = transactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transactionMonth == currentMonth && transactionYear == currentYear
        }
        
        guard !currentMonthTransactions.isEmpty else { return insights }
        
        // Самые большие расходы
        let topExpenses = currentMonthTransactions
            .filter { $0.type == .expense }
            .sorted { $0.amount > $1.amount }
            .prefix(3)
        
        if let largestExpense = topExpenses.first {
            insights.append(FinancialInsight(
                type: .largestExpense,
                title: "Самый крупный расход",
                message: "\(formatCurrency(largestExpense.amount)) - \(largestExpense.description)",
                value: largestExpense.amount,
                category: largestExpense.category
            ))
        }
        
        // Анализ экономии
        let totalIncome = currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let totalExpenses = currentMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        if totalIncome > 0 {
            let savingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100
            
            // ЗАЩИТА ОТ NaN И БЕСКОНЕЧНОСТИ
            let safeSavingsRate = savingsRate.isFinite ? savingsRate : 0
            let savingsType: FinancialInsight.InsightType = safeSavingsRate >= 0 ? .savingsRate : .overspending
            
            insights.append(FinancialInsight(
                type: savingsType,
                title: safeSavingsRate >= 0 ? "Норма сбережений" : "Перерасход",
                message: safeSavingsRate >= 0 ?
                    "Вы сохраняете \(safeInt(safeSavingsRate))% от доходов" :
                    "Перерасход \(safeInt(abs(safeSavingsRate)))% от доходов",
                value: safeSavingsRate,
                category: nil
            ))
        }
        
        // Основная категория расходов
        let categoryBreakdown = calculateCategoryBreakdown(transactions: currentMonthTransactions)
        if let topCategory = categoryBreakdown.max(by: { $0.amount < $1.amount }) {
            // ЗАЩИТА ОТ ДЕЛЕНИЯ НА НОЛЬ
            let percentage = totalExpenses > 0 ? (topCategory.amount / totalExpenses) * 100 : 0
            let safePercentage = percentage.isFinite ? percentage : 0
            
            insights.append(FinancialInsight(
                type: .topSpendingCategory,
                title: "Основная категория расходов",
                message: "\(safeInt(safePercentage))% трат на \(topCategory.category.rawValue)",
                value: topCategory.amount,
                category: topCategory.category
            ))
        }
        
        return insights
    }
    
    private func calculateCategoryBreakdown(transactions: [FinancialTransaction]) -> [CategoryBreakdown] {
        let expenseTransactions = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenseTransactions, by: { $0.category })
        
        return grouped.map { category, transactions in
            let total = transactions.reduce(0) { $0 + $1.amount }
            return CategoryBreakdown(category: category, amount: total)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BYN"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) ₽"
    }
}

// MARK: - Supporting Structures (ТОЛЬКО те, которых нет в других файлах)

struct SpendingTrend: Identifiable {
    let id = UUID()
    let period: Date
    let totalExpenses: Double
    let totalIncome: Double
    let changePercentage: Double?
    let categoryBreakdown: [CategoryBreakdown]
}

struct BudgetAlert: Identifiable {
    let id = UUID()
    let category: TransactionCategory
    let spentAmount: Double
    let budgetLimit: Double
    let percentage: Double
    let alertType: AlertType
    
    enum AlertType {
        case warning
        case exceeded
    }
}

struct FinancialInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let value: Double
    let category: TransactionCategory?
    
    enum InsightType {
        case largestExpense
        case savingsRate
        case overspending
        case topSpendingCategory
        case budgetWarning
        case frequentSpending
        case spendingIncrease
        case spendingDecrease
    }
}

// УДАЛИТЕ дублирующее определение CategoryBreakdown отсюда!
// Оно уже должно быть определено в другом файле
