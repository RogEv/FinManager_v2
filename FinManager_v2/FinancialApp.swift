//
//  FinancialApp.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation

// Основные модули
struct FinancialApp {
    let smsParser: SMSParser
    let transactionManager: TransactionManager
    let analyticsEngine: AnalyticsEngine
    let uiManager: UIManager
    
    init() {
        self.uiManager = UIManager()
        self.analyticsEngine = AnalyticsEngine()
        self.smsParser = SMSParser()
        self.transactionManager = TransactionManager()
    }
}
