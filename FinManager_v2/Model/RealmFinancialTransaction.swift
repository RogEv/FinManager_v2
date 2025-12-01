//
//  RealmFinancialTransaction.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 1.12.25.
//

import Foundation
import RealmSwift

class RealmFinancialTransaction: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var amount: Double = 0.0
    @Persisted var categoryRaw: String = ""
    @Persisted var date: Date = Date()
    @Persisted var transactionDescription: String = ""
    @Persisted var typeString: String = ""
    
    var category: TransactionCategory {
        get { TransactionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    var type: TransactionType {
            get {
                switch typeString {
                case "income": return .income
                default: return .expense
                }
            }
            set {
                switch newValue {
                case .expense: typeString = "expense"
                case .income: typeString = "income"
                }
            }
        }
    
    convenience init(from transaction: FinancialTransaction) {
        self.init()
        self.id = transaction.id.uuidString
        self.amount = transaction.amount
        self.category = transaction.category
        self.date = transaction.date
        self.transactionDescription = transaction.description
        self.type = transaction.type
    }
    
    func toFinancialTransaction() -> FinancialTransaction {
        let transactionType: TransactionType = typeString == "income" ? .income : .expense
        return FinancialTransaction(
            id: UUID(uuidString: id) ?? UUID(),
            amount: amount,
            category: category,
            date: date,
            description: transactionDescription,
            type: type
        )
    }
}
