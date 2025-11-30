//
//  SummaryView.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation
import SwiftUI

struct SummaryView: View {
    let summary: MonthlySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Финансовая сводка")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                // Доходы
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                        Text("Доходы")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formatCurrency(summary.income))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Расходы
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.red)
                        Text("Расходы")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formatCurrency(summary.expenses))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // Сбережения
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: summary.savings >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                            .foregroundColor(summary.savings >= 0 ? .blue : .orange)
                        Text("Баланс")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formatCurrency(summary.savings))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(summary.savings >= 0 ? .blue : .orange)
                }
            }
            
            // Progress bar для визуализации соотношения доходов/расходов
            if summary.income > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Соотношение доходов и расходов")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .frame(height: 8)
                            .foregroundColor(.gray.opacity(0.3))
                        
                        HStack(spacing: 0) {
                            Capsule()
                                .frame(width: calculateExpenseRatio() * 200, height: 8)
                                .foregroundColor(.red)
                            
                            Capsule()
                                .frame(width: calculateSavingsRatio() * 200, height: 8)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 200)
                    
                    HStack {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Расходы: \(Int(calculateExpenseRatio() * 100))%")
                                .font(.caption2)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("Сбережения: \(Int(calculateSavingsRatio() * 100))%")
                                .font(.caption2)
                        }
                    }
                }
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
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) ₽"
    }
    
    private func calculateExpenseRatio() -> Double {
        guard summary.income > 0 else { return 0 }
        return min(summary.expenses / summary.income, 1.0)
    }
    
    private func calculateSavingsRatio() -> Double {
        guard summary.income > 0 else { return 0 }
        return max(summary.savings / summary.income, 0)
    }
}

#Preview {
    SummaryView(summary: MonthlySummary(
        income: 150000,
        expenses: 120000,
        savings: 30000
    ))
    .previewLayout(.sizeThatFits)
}
