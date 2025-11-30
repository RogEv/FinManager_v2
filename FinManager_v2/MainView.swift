//
//  MainView.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var transactionManager = TransactionManager()
    @State private var showingSMSInput = false
    @State private var smsText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Сводка
                if let summary = transactionManager.monthlySummary {
                    SummaryView(summary: summary)
                }
                
                // Графики по категориям
                CategoryBreakdownView(breakdown: transactionManager.getCategoryBreakdown())
                
                // Список транзакций
                List(transactionManager.transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
                
                Spacer()
            }
            .navigationTitle("Финансовый помощник")
            .toolbar {
                Button("Добавить SMS") {
                    showingSMSInput = true
                }
            }
        }
        .sheet(isPresented: $showingSMSInput) {
            SMSInputView(smsText: $smsText) {
                transactionManager.processSMSMessages([smsText])
                smsText = ""
            }
        }
    }
}

struct SMSInputView: View {
    @Binding var smsText: String
    let onProcess: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $smsText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(height: 200)
                
                Button("Проанализировать") {
                    onProcess()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Введите SMS")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
