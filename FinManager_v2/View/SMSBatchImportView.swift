//
//  SMSBatchImportView.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import SwiftUI

struct SMSBatchImportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var transactionManager: TransactionManager
    @State private var smsText = ""
    @State private var importResult: ImportResult?
    @State private var isImporting = false
    @State private var showOnlyErrors = false
    
    var filteredErrors: [String] {
        if showOnlyErrors {
            return importResult?.errors ?? []
        } else {
            return []
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isImporting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.blue)
                        
                        Text("Обработка SMS...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Анализируем \(smsText.components(separatedBy: .newlines).count) сообщений")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Вставьте SMS сообщения")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Каждое SMS с новой строки. Поддерживаются форматы:\n• Karta 4***9392 01-11-25 13:42:20. Oplata...\n• <#> 02/11 17:34. Platezh s DK9392...\n• Na vashu kartu zachisleno...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $smsText)
                                .frame(height: 200)
                                .padding(4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .font(.system(.body, design: .monospaced))
                            
                            if smsText.isEmpty {
                                Text("Вставьте SMS сообщения здесь...\n\nПример:\nKarta 4***9392 01-11-25 13:42:20. Oplata 67.95 BYN. BLR LAMODA.BY. Dostupno: 1298.77 BYN")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        // Статистика введенных сообщений
                        if !smsText.isEmpty {
                            HStack {
                                Text("Сообщений: \(smsText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("Очистить") {
                                    smsText = ""
                                    importResult = nil
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if let result = importResult {
                        ImportResultView(
                            result: result,
                            showOnlyErrors: $showOnlyErrors,
                            filteredErrors: filteredErrors
                        )
                    }
                    
                    Spacer()
                    
                    // Подсказка внизу
                    VStack(spacing: 8) {
                        Text("Совет: Вы можете копировать сразу несколько SMS из приложения банка")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Label("Автоопределение категорий", systemImage: "tag")
                                .font(.caption2)
                            
                            Label("Фильтрация дубликатов", systemImage: "checkmark.circle")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Импорт SMS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Button("Импорт") {
                        importSMS()
                    }
                    .disabled(smsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func importSMS() {
        isImporting = true
        importResult = nil
        
        let messages = smsText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.transactionManager.importMultipleSMS(messages)
            
            DispatchQueue.main.async {
                self.importResult = result
                self.isImporting = false
                
                print("🎯 Импорт завершен. Добавлено: \(result.importedCount)")
                
                if result.failedCount == 0 && result.importedCount > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss()
                    }
                }
            }
        }
    }
}

struct ImportResultView: View {
    let result: ImportResult
    @Binding var showOnlyErrors: Bool
    let filteredErrors: [String]
    
    var body: some View {
        VStack(spacing: 16) {
            // Заголовок с результатами
            HStack {
                Image(systemName: result.failedCount == 0 ? "checkmark.circle.fill" :
                     result.importedCount > 0 ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.failedCount == 0 ? .green :
                                   result.importedCount > 0 ? .orange : .red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.failedCount == 0 ? "Импорт завершен" :
                         result.importedCount > 0 ? "Импорт с ошибками" : "Импорт не удался")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Успешно: \(result.importedCount), Ошибок: \(result.failedCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !result.errors.isEmpty {
                    Toggle("Только ошибки", isOn: $showOnlyErrors)
                        .font(.caption)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            
            // Прогресс-бар
            if result.importedCount + result.failedCount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Обработано:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(result.importedCount + result.failedCount) сообщений")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: successWidth(in: geometry.size.width), height: 6)
                                    .cornerRadius(3)
                                
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: errorWidth(in: geometry.size.width), height: 6)
                                    .cornerRadius(3)
                            }
                        }
                    }
                    .frame(height: 6)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Успешно: \(result.importedCount)")
                                .font(.caption2)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("Ошибки: \(result.failedCount)")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Список ошибок
            if !filteredErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ошибки обработки (\(filteredErrors.count)):")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if filteredErrors.count > 10 {
                            Text("Показаны первые 10")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(filteredErrors.prefix(10).enumerated()), id: \.offset) { index, error in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(width: 20, alignment: .trailing)
                                    
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Подсказка после импорта
            if result.importedCount > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("Транзакции добавлены в историю")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private func successWidth(in totalWidth: CGFloat) -> CGFloat {
        let total = result.importedCount + result.failedCount
        guard total > 0 else { return 0 }
        return totalWidth * CGFloat(result.importedCount) / CGFloat(total)
    }
    
    private func errorWidth(in totalWidth: CGFloat) -> CGFloat {
        let total = result.importedCount + result.failedCount
        guard total > 0 else { return 0 }
        return totalWidth * CGFloat(result.failedCount) / CGFloat(total)
    }
}

// Предпросмотр для SwiftUI Canvas
#Preview {
    SMSBatchImportView(transactionManager: TransactionManager())
}

//#Preview("С результатами") {
//    let transactionManager = TransactionManager()
//    
//    return SMSBatchImportView(
//        transactionManager: transactionManager,
//        importResult: ImportResult(
//            importedCount: 15,
//            failedCount: 3,
//            errors: [
//                "Не удалось распознать: Karta 4***9392 01-11-25 13:42:20...",
//                "Дубликат: LAMODA.BY",
//                "Не удалось определить сумму: Invalid transaction"
//            ]
//        )
//    )
//}
