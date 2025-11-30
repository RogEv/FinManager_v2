//
//  TransactionRow.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation
import SwiftUI

struct TransactionRow: View {
    let transaction: FinancialTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка категории
            CategoryIcon(category: transaction.category, type: transaction.type)
            
            // Основная информация
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(transaction.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(formatDate(transaction.date))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Сумма
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(transaction.amount))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForAmount(transaction.amount, type: transaction.type))
                
                Text(transaction.type == .income ? "Доход" : "Расход")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(backgroundColorForType(transaction.type))
                    )
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.maximumFractionDigits = transaction.amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) ₽"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    private func colorForAmount(_ amount: Double, type: TransactionType) -> Color {
        switch type {
        case .income:
            return .green
        case .expense:
            return .red
        }
    }
    
    private func backgroundColorForType(_ type: TransactionType) -> Color {
        switch type {
        case .income:
            return .green.opacity(0.2)
        case .expense:
            return .red.opacity(0.2)
        }
    }
}

// MARK: - Category Icon Component (остается без изменений)

struct CategoryIcon: View {
    let category: TransactionCategory
    let type: TransactionType
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColorForCategory(category))
                .frame(width: 44, height: 44)
            
            Image(systemName: iconNameForCategory(category))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColorForCategory(category))
        }
    }
    
    private func iconNameForCategory(_ category: TransactionCategory) -> String {
        switch category {
        case .food:
            return "fork.knife"
        case .transportation:
            return "car.fill"
        case .entertainment:
            return "film"
        case .shopping:
            return "bag.fill"
        case .bills:
            return "house.fill"
        case .salary:
            return "dollarsign.circle.fill"
        case .transfer:
            return "arrow.left.arrow.right"
        case .cash:
            return "banknote"
        case .other:
            return "questionmark.circle"
        }
    }
    
    private func backgroundColorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food:
            return .orange.opacity(0.2)
        case .transportation:
            return .blue.opacity(0.2)
        case .entertainment:
            return .purple.opacity(0.2)
        case .shopping:
            return .pink.opacity(0.2)
        case .bills:
            return .green.opacity(0.2)
        case .salary:
            return .green.opacity(0.3)
        case .transfer:
            return .gray.opacity(0.2)
        case .cash:
            return .brown.opacity(0.2)
        case .other:
            return .secondary.opacity(0.2)
        }
    }

    private func iconColorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food:
            return .orange
        case .transportation:
            return .blue
        case .entertainment:
            return .purple
        case .shopping:
            return .pink
        case .bills:
            return .green
        case .salary:
            return .green
        case .transfer:
            return .gray
        case .cash:
            return .brown
        case .other:
            return .secondary
        }
    }
}
