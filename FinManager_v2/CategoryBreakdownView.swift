//
//  CategoryBreakdownView.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation
import SwiftUI
import Charts

struct CategoryBreakdownView: View {
    let breakdown: [CategoryBreakdown]
    var onAddManualTransaction: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Расходы по категориям")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let onAddManualTransaction = onAddManualTransaction {
                    Button(action: onAddManualTransaction) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if breakdown.isEmpty {
                EmptyCategoryView()
            } else {
                ChartView(breakdown: breakdown)
                CategoryListView(breakdown: breakdown)
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
}

// MARK: - Subviews for CategoryBreakdownView

private struct EmptyCategoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("Нет данных о расходах")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Добавьте SMS с транзакциями для анализа")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

private struct ChartView: View {
    let breakdown: [CategoryBreakdown]
    
    var body: some View {
        Chart(breakdown) { item in
            SectorMark(
                angle: .value("Расходы", item.amount),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(colorForCategory(item.category))
            .annotation(position: .overlay) {
                if (item.amount / totalAmount) > 0.1 {
                    Text("\(Int((item.amount / totalAmount) * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 200)
        .chartLegend(.hidden)
    }
    
    private var totalAmount: Double {
        breakdown.reduce(0) { $0 + $1.amount }
    }
    
    private func colorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food: return .orange
        case .transportation: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .bills: return .green
        case .salary: return .green.opacity(0.7)
        case .transfer: return .gray
        case .other: return .brown
        case .cash: return .red.opacity(0.7)
        }
    }
}

private struct CategoryListView: View {
    let breakdown: [CategoryBreakdown]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(sortedBreakdown.prefix(5), id: \.category) { item in
                CategoryRow(item: item, totalAmount: totalAmount)
            }
        }
    }
    
    private var sortedBreakdown: [CategoryBreakdown] {
        breakdown.sorted { $0.amount > $1.amount }
    }
    
    private var totalAmount: Double {
        breakdown.reduce(0) { $0 + $1.amount }
    }
}

private struct CategoryRow: View {
    let item: CategoryBreakdown
    let totalAmount: Double
    
    var body: some View {
        HStack {
            // Цветной индикатор категории
            Circle()
                .fill(colorForCategory(item.category))
                .frame(width: 12, height: 12)
            
            // Название категории
            Text(item.category.rawValue.capitalized)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Процент и сумма
            VStack(alignment: .trailing) {
                Text("\(Int((item.amount / totalAmount) * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(item.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food: return .orange
        case .transportation: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .bills: return .green
        case .salary: return .green.opacity(0.7)
        case .transfer: return .gray
        case .other: return .brown
        case .cash: return .red.opacity(0.7)
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

#Preview {
    VStack {
        CategoryBreakdownView(breakdown: [
            CategoryBreakdown(category: .food, amount: 25000),
            CategoryBreakdown(category: .transportation, amount: 15000),
            CategoryBreakdown(category: .shopping, amount: 35000),
            CategoryBreakdown(category: .entertainment, amount: 12000),
            CategoryBreakdown(category: .bills, amount: 18000)
        ])
        
        CategoryBreakdownView(breakdown: [])
    }
    .previewLayout(.sizeThatFits)
}
