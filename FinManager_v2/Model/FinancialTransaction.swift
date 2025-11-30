//
//  FinancialTransaction.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation
import NaturalLanguage

struct FinancialTransaction: Identifiable {
    let id = UUID()
    let amount: Double
    let category: TransactionCategory
    let date: Date
    let description: String
    let type: TransactionType
}

enum TransactionCategory: String, CaseIterable {
    case food = "Еда"
    case transportation = "Транспорт"
    case entertainment = "Развлечения"
    case shopping = "Шоппинг"
    case bills = "Счета"
    case salary = "Зарплата"
    case transfer = "Переводы"
    case cash = "Наличные"
    case other = "Другое"
    
    var iconName: String {
        switch self {
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
}

enum TransactionType {
    case income, expense
}

