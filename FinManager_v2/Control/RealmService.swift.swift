//
//  RealmService.swift.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 1.12.25.
//

import Foundation
import RealmSwift

class RealmService: ObservableObject {
    private var realm: Realm?
    
    init() {
        setupRealm()
    }
    
    private func setupRealm() {
        do {
            // Конфигурация Realm
            let config = Realm.Configuration(
                schemaVersion: 1,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 1 {
                        // Миграция при необходимости
                    }
                }
            )
            
            Realm.Configuration.defaultConfiguration = config
            realm = try Realm()
            
            print("✅ Realm инициализирован. Путь: \(Realm.Configuration.defaultConfiguration.fileURL?.path ?? "неизвестно")")
        } catch {
            print("❌ Ошибка инициализации Realm: \(error)")
        }
    }
    
    // MARK: - CRUD операции
    
    func saveTransaction(_ transaction: FinancialTransaction) {
        guard let realm = realm else { return }
        
        do {
            let realmTransaction = RealmFinancialTransaction(from: transaction)
            try realm.write {
                realm.add(realmTransaction, update: .modified)
            }
            print("✅ Транзакция сохранена в Realm: \(transaction.description)")
        } catch {
            print("❌ Ошибка сохранения транзакции: \(error)")
        }
    }
    
    func saveTransactions(_ transactions: [FinancialTransaction]) {
        guard let realm = realm else { return }
        
        do {
            let realmTransactions = transactions.map { RealmFinancialTransaction(from: $0) }
            try realm.write {
                realm.add(realmTransactions, update: .modified)
            }
            print("✅ Сохранено \(transactions.count) транзакций в Realm")
        } catch {
            print("❌ Ошибка сохранения транзакций: \(error)")
        }
    }
    
    func loadAllTransactions() -> [FinancialTransaction] {
        guard let realm = realm else { return [] }
        
        let realmTransactions = realm.objects(RealmFinancialTransaction.self)
            .sorted(byKeyPath: "date", ascending: false)
        
        return Array(realmTransactions).map { $0.toFinancialTransaction() }
    }
    
    func deleteTransaction(_ transaction: FinancialTransaction) {
        guard let realm = realm else { return }
        
        do {
            if let realmTransaction = realm.object(
                ofType: RealmFinancialTransaction.self,
                forPrimaryKey: transaction.id.uuidString
            ) {
                try realm.write {
                    realm.delete(realmTransaction)
                }
                print("✅ Транзакция удалена из Realm: \(transaction.description)")
            }
        } catch {
            print("❌ Ошибка удаления транзакции: \(error)")
        }
    }
    
    func deleteAllTransactions() {
        guard let realm = realm else { return }
        
        do {
            let allTransactions = realm.objects(RealmFinancialTransaction.self)
            try realm.write {
                realm.delete(allTransactions)
            }
            print("✅ Все транзакции удалены из Realm")
        } catch {
            print("❌ Ошибка удаления всех транзакций: \(error)")
        }
    }
    
    // MARK: - Фильтрация и поиск
    
    func getTransactions(for month: Date) -> [FinancialTransaction] {
        guard let realm = realm else { return [] }
        
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfMonth as NSDate,
            startOfNextMonth as NSDate
        )
        
        let realmTransactions = realm.objects(RealmFinancialTransaction.self)
            .filter(predicate)
            .sorted(byKeyPath: "date", ascending: false)
        
        return Array(realmTransactions).map { $0.toFinancialTransaction() }
    }
    
    func getTransactionsByCategory(_ category: TransactionCategory) -> [FinancialTransaction] {
        guard let realm = realm else { return [] }
        
        let realmTransactions = realm.objects(RealmFinancialTransaction.self)
            .filter("categoryRaw == %@", category.rawValue)
            .sorted(byKeyPath: "date", ascending: false)
        
        return Array(realmTransactions).map { $0.toFinancialTransaction() }
    }
}
