//
//  ManualTransactionView.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 30.11.25.
//

import Foundation
import SwiftUI

struct ManualTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var transactionManager: TransactionManager
    
    @State private var amount: String = ""
    @State private var selectedCategory: TransactionCategory = .food
    @State private var selectedType: TransactionType = .expense
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    HStack {
                        Text("Тип")
                        Picker("", selection: $selectedType) {
                            Text("Расход").tag(TransactionType.expense)
                            Text("Доход").tag(TransactionType.income)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HStack {
                        Text("Сумма")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("BYN")
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Дата", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Категория")) {
                    Picker("Категория", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: iconForCategory(category))
                                    .foregroundColor(colorForCategory(category))
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Описание")) {
                    TextField("Введите описание...", text: $description)
                }
            }
            .navigationTitle("Новая транзакция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        addTransaction()
                    }
                    .disabled(amount.isEmpty || Double(amount) == nil)
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Пожалуйста, проверьте введенные данные")
            }
        }
    }
    
    private func addTransaction() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")),
              amountValue > 0 else {
            showError = true
            return
        }
        
        let success = transactionManager.addManualTransaction(
            amount: amountValue,
            category: selectedCategory,
            date: date,
            description: description.isEmpty ? "Ручная операция" : description,
            type: selectedType
        )
        
        if success {
            dismiss()
        } else {
            showError = true
        }
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
}
