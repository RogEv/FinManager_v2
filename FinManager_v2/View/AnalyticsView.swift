//
//  AnalyticsView.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 30.11.25.
//

import Foundation
import SwiftUI
import Charts

struct AnalyticsView: View {
    let trends: [SpendingTrend]
    let breakdown: [CategoryBreakdown]
    let transactions: [FinancialTransaction]
    
    @State private var selectedTimeFrame = 0
    private let timeFrames = ["Месяц", "3 месяца", "Год"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if trends.isEmpty && breakdown.isEmpty {
                    EmptyAnalyticsView()
                } else {
                    // Сегментированный контрол для выбора периода
                    Picker("Период", selection: $selectedTimeFrame) {
                        ForEach(0..<timeFrames.count, id: \.self) { index in
                            Text(timeFrames[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Сводная статистика
                    AnalyticsSummaryView(trends: trends, transactions: transactions)
                    
                    // График трендов
                    if !trends.isEmpty {
                        SpendingTrendsChart(trends: filteredTrends)
                    }
                    
                    // Распределение по категориям
                    if !breakdown.isEmpty {
                        CategoryAnalyticsView(breakdown: breakdown)
                    }
                    
                    // Сравнение месяцев
                    if trends.count > 1 {
                        MonthlyComparisonView(trends: trends)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Аналитика")
        .background(Color(.systemGroupedBackground))
    }
    
    private var filteredTrends: [SpendingTrend] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeFrame {
        case 0: // Месяц
            return trends.filter { trend in
                calendar.isDate(trend.period, equalTo: now, toGranularity: .month)
            }
        case 1: // 3 месяца
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            return trends.filter { $0.period >= threeMonthsAgo }
        case 2: // Год
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return trends.filter { $0.period >= oneYearAgo }
        default:
            return trends
        }
    }
}

struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Недостаточно данных для анализа")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Добавьте несколько транзакций, чтобы увидеть аналитику")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Импортируйте SMS от банка", systemImage: "message")
                Label("Добавьте транзакции вручную", systemImage: "square.and.pencil")
                Label("Подождите несколько операций", systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct AnalyticsSummaryView: View {
    let trends: [SpendingTrend]
    let transactions: [FinancialTransaction]
    
    private var currentMonthTrend: SpendingTrend? {
        let currentMonth = Calendar.current.component(.month, from: Date())
        return trends.first { trend in
            Calendar.current.component(.month, from: trend.period) == currentMonth
        }
    }
    
    private var totalSpent: Double {
        trends.reduce(0) { $0 + $1.totalExpenses }
    }
    
    private var averageMonthlySpending: Double {
        guard !trends.isEmpty else { return 0 }
        return totalSpent / Double(trends.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Сводка")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Всего потрачено",
                    value: formatCurrency(totalSpent),
                    icon: "dollarsign.circle",
                    color: .red
                )
                
                StatCard(
                    title: "В среднем в месяц",
                    value: formatCurrency(averageMonthlySpending),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                StatCard(
                    title: "Всего транзакций",
                    value: "\(transactions.count)",
                    icon: "list.bullet",
                    color: .green
                )
                
                if let currentMonth = currentMonthTrend {
                    StatCard(
                        title: "Текущий месяц",
                        value: formatCurrency(currentMonth.totalExpenses),
                        icon: "calendar",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BYN"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) ₽"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SpendingTrendsChart: View {
    let trends: [SpendingTrend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Динамика расходов")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(trends.sorted(by: { $0.period < $1.period })) { trend in
                    LineMark(
                        x: .value("Месяц", monthFormatter.string(from: trend.period)),
                        y: .value("Расходы", trend.totalExpenses)
                    )
                    .foregroundStyle(.red)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Месяц", monthFormatter.string(from: trend.period)),
                        y: .value("Расходы", trend.totalExpenses)
                    )
                    .foregroundStyle(.red.opacity(0.1))
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(formatCurrency(doubleValue))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BYN"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) ₽"
    }
}

private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM yy"
    formatter.locale = Locale(identifier: "ru_RU")
    return formatter
}()

struct CategoryAnalyticsView: View {
    let breakdown: [CategoryBreakdown]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Расходы по категориям")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(breakdown.sorted { $0.amount > $1.amount }.prefix(6)) { item in
                    CategoryStatCard(item: item, totalAmount: totalAmount)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var totalAmount: Double {
        breakdown.reduce(0) { $0 + $1.amount }
    }
}

struct CategoryStatCard: View {
    let item: CategoryBreakdown
    let totalAmount: Double
    
    var body: some View {
        HStack {
            Image(systemName: iconForCategory(item.category))
                .foregroundColor(colorForCategory(item.category))
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int((item.amount / totalAmount) * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatCurrency(item.amount))
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(8)
        .background(colorForCategory(item.category).opacity(0.1))
        .cornerRadius(6)
    }
    
    private func iconForCategory(_ category: TransactionCategory) -> String {
        switch category {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .entertainment: return "film"
        case .shopping: return "bag.fill"
        case .bills: return "house.fill"
        case .salary: return "dollarsign.circle.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .cash: return "banknote"
        case .other: return "questionmark.circle"
        }
    }

    private func colorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food: return .orange
        case .transportation: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .bills: return .green
        case .salary: return .green
        case .transfer: return .gray
        case .cash: return .brown
        case .other: return .secondary
        }
    }

    private func backgroundColorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food: return .orange.opacity(0.2)
        case .transportation: return .blue.opacity(0.2)
        case .entertainment: return .purple.opacity(0.2)
        case .shopping: return .pink.opacity(0.2)
        case .bills: return .green.opacity(0.2)
        case .salary: return .green.opacity(0.3)
        case .transfer: return .gray.opacity(0.2)
        case .cash: return .brown.opacity(0.2)
        case .other: return .secondary.opacity(0.2)
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

struct MonthlyComparisonView: View {
    let trends: [SpendingTrend]
    
    private var lastTwoMonths: [SpendingTrend] {
        Array(trends.sorted { $0.period > $1.period }.prefix(2))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Сравнение месяцев")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if lastTwoMonths.count == 2 {
                let current = lastTwoMonths[0]
                let previous = lastTwoMonths[1]
                let change = current.totalExpenses - previous.totalExpenses
                let percentage = previous.totalExpenses > 0 ? (change / previous.totalExpenses) * 100 : 0
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Текущий месяц")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(current.totalExpenses))
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Изменение")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            Text("\(Int(abs(percentage)))%")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(change >= 0 ? .red : .green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BYN"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) ₽"
    }
}
