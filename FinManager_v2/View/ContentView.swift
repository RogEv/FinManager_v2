//
//  ContentView.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var transactionManager = TransactionManager()
    @StateObject private var uiManager = UIManager()
    @StateObject private var analyticsEngine = AnalyticsEngine()
    
    @State private var showingManualTransaction = false
    @State private var showingSMSInput = false
    @State private var showingBatchImport = false
    @State private var smsText = ""
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Сводка
                        if let summary = transactionManager.monthlySummary {
                            SummaryView(summary: summary)
                        }
                        
                        // Графики по категориям с кнопкой добавления
                        CategoryBreakdownView(
                            breakdown: transactionManager.getCategoryBreakdown(),
                            onAddManualTransaction: {
                                showingManualTransaction = true
                            }
                        )
                        
                        // Инсайты от аналитики
                        if !analyticsEngine.financialInsights.isEmpty {
                            FinancialInsightsView(insights: analyticsEngine.financialInsights)
                        }
                        
                        // Уведомления о бюджете
                        if !analyticsEngine.budgetAlerts.isEmpty {
                            BudgetAlertsView(alerts: analyticsEngine.budgetAlerts)
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Финансовый помощник")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingSMSInput = true
                            } label: {
                                Label("Одно SMS", systemImage: "message")
                            }
                            
                            Button {
                                showingBatchImport = true
                            } label: {
                                Label("Массовый импорт", systemImage: "doc.text.magnifyingglass")
                            }
                            
                            Button {
                                showingManualTransaction = true
                            } label: {
                                Label("Вручную", systemImage: "square.and.pencil")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Главная")
            }
            .tag(0)
            
            // Вкладка с историей транзакций
            NavigationView {
                TransactionsListView(transactions: transactionManager.transactions)
                    .navigationTitle("История операций")
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("История")
            }
            .tag(1)
            
            // Вкладка с аналитикой
            NavigationView {
                AnalyticsView(
                    trends: analyticsEngine.spendingTrends,
                    breakdown: transactionManager.getCategoryBreakdown(),
                    transactions: transactionManager.transactions
                )
                .navigationTitle("Аналитика")
            }
            .tabItem {
                Image(systemName: "chart.pie.fill")
                Text("Аналитика")
            }
            .tag(2)
            
            // Вкладка с настройками
            NavigationView {
                SettingsView(uiManager: uiManager)
                    .navigationTitle("Настройки")
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Настройки")
            }
            .tag(3)
        }
        .sheet(isPresented: $showingBatchImport) {
                SMSBatchImportView(transactionManager: transactionManager) 
            }
        .sheet(isPresented: $showingManualTransaction) {
                    ManualTransactionView(transactionManager: transactionManager)
                }
        .accentColor(.blue)
        .sheet(isPresented: $showingSMSInput) {
            SMSInputView(smsText: $smsText) {
                if !smsText.isEmpty {
                    transactionManager.processSMSMessages([smsText])
                    smsText = ""
                    
                    // Обновляем аналитику после добавления новой транзакции
                    analyticsEngine.analyzeSpendingTrends(transactions: transactionManager.transactions)
                    analyticsEngine.checkBudgetLimits(transactions: transactionManager.transactions)
                    analyticsEngine.generateFinancialInsights(transactions: transactionManager.transactions)
                }
            }
        }
        .onAppear {
            // Инициализируем аналитику при первом запуске
            analyticsEngine.analyzeSpendingTrends(transactions: transactionManager.transactions)
            analyticsEngine.checkBudgetLimits(transactions: transactionManager.transactions)
            analyticsEngine.generateFinancialInsights(transactions: transactionManager.transactions)
        }
    }
}

// MARK: - Дополнительные компоненты

struct FinancialInsightsView: View {
    let insights: [FinancialInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Финансовые инсайты")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(insights.prefix(3)) { insight in
                HStack {
                    Image(systemName: iconForInsight(insight.type))
                        .foregroundColor(colorForInsight(insight.type))
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(insight.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private func iconForInsight(_ type: FinancialInsight.InsightType) -> String {
        switch type {
        case .largestExpense: return "arrow.up.circle"
        case .savingsRate: return "percent"
        case .overspending: return "exclamationmark.triangle.fill"
        case .topSpendingCategory: return "chart.bar.fill"
        case .budgetWarning: return "exclamationmark.triangle"
        case .frequentSpending: return "repeat.circle"
        case .spendingIncrease: return "chart.line.uptrend.xyaxis"
        case .spendingDecrease: return "chart.line.downtrend.xyaxis"
        }
    }

    private func colorForInsight(_ type: FinancialInsight.InsightType) -> Color {
        switch type {
        case .largestExpense: return .red
        case .savingsRate: return .green
        case .overspending: return .orange
        case .topSpendingCategory: return .blue
        case .budgetWarning: return .orange
        case .frequentSpending: return .purple
        case .spendingIncrease: return .red
        case .spendingDecrease: return .green
        }
    }
}

struct BudgetAlertsView: View {
    let alerts: [BudgetAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Уведомления о бюджете")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(alerts) { alert in
                HStack {
                    Image(systemName: alert.alertType == .exceeded ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                        .foregroundColor(alert.alertType == .exceeded ? .red : .orange)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(alert.category.rawValue.capitalized)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(alertMessage(for: alert))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(alert.percentage))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(alert.alertType == .exceeded ? .red : .orange)
                }
                .padding()
                .background(alert.alertType == .exceeded ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private func alertMessage(for alert: BudgetAlert) -> String {
        let spent = formatCurrency(alert.spentAmount)
        let limit = formatCurrency(alert.budgetLimit)
        
        if alert.alertType == .exceeded {
            return "Превышен лимит! \(spent) из \(limit)"
        } else {
            return "Приближаетесь к лимиту: \(spent) из \(limit)"
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) ₽"
    }
}

struct TransactionsListView: View {
    let transactions: [FinancialTransaction]
    
    var body: some View {
        List {
            if transactions.isEmpty {
                EmptyStateView()
            } else {
                ForEach(transactions.sorted { $0.date > $1.date }) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .listStyle(.plain)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Нет транзакций")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Добавьте SMS от банка для анализа ваших финансов")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

//struct AnalyticsView: View {
//    let trends: [SpendingTrend]
//    let breakdown: [CategoryBreakdown]
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                if trends.isEmpty {
//                    Text("Недостаточно данных для анализа")
//                        .foregroundColor(.secondary)
//                        .padding()
//                } else {
//                    // Здесь можно добавить графики трендов
//                    // и дополнительную аналитику
//                    Text("Аналитика в разработке")
//                        .foregroundColor(.secondary)
//                }
//            }
//            .padding()
//        }
//    }
//}

struct SettingsView: View {
    @ObservedObject var uiManager: UIManager
    
    var body: some View {
        Form {
            Section(header: Text("Внешний вид")) {
                Picker("Тема", selection: $uiManager.currentTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                
                Toggle("Тактильные отклики", isOn: $uiManager.hapticFeedbackEnabled)
            }
            
            Section(header: Text("Форматирование")) {
                Picker("Формат даты", selection: $uiManager.dateFormat) {
                    Text("Короткий").tag(DateFormatStyle.short)
                    Text("Средний").tag(DateFormatStyle.medium)
                    Text("Полный").tag(DateFormatStyle.long)
                    Text("Только время").tag(DateFormatStyle.timeOnly)
                }
            }
            
            Section(header: Text("О приложении")) {
                HStack {
                    Text("Версия")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Разработчик")
                    Spacer()
                    Text("FinManager Team")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
