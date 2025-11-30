//
//  UIManager.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import SwiftUI
import UIKit

class UIManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    @Published var currencySymbol: String = "₽"
    @Published var dateFormat: DateFormatStyle = .medium
    @Published var hapticFeedbackEnabled: Bool = true
    
    // Цвета для категорий
    func colorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food: return .orange
        case .transportation: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .bills: return .green
        case .salary: return .green.opacity(0.7)
        case .transfer: return .gray
        case .cash: return .red.opacity(0.7)
        case .other: return .brown
        }
    }
    
    // Иконки для категорий
    func iconForCategory(_ category: TransactionCategory) -> String {
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
    
    // Форматирование валюты
    func formatCurrency(_ amount: Double, showCents: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = showCents ? 2 : 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currencySymbol)"
    }
    
    // Форматирование даты
    func formatDate(_ date: Date, style: DateFormatStyle? = nil) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        
        let formatStyle = style ?? dateFormat
        
        switch formatStyle {
        case .short:
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        case .medium:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        case .long:
            formatter.dateStyle = .long
            formatter.timeStyle = .short
        case .timeOnly:
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        }
        
        return formatter.string(from: date)
    }
    
    // Анимации
    func transactionAnimation(for type: TransactionType) -> Animation {
        switch type {
        case .income:
            return .spring(response: 0.6, dampingFraction: 0.8)
        case .expense:
            return .easeInOut(duration: 0.4)
        }
    }
    
    // Тактильная обратная связь
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticFeedbackEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // Градиенты для карточек
    func cardGradient(for type: CardType) -> LinearGradient {
        switch type {
        case .summary:
            return LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .analytics:
            return LinearGradient(
                colors: [.green, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .insights:
            return LinearGradient(
                colors: [.orange, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Стили для текста
    func textStyle(for style: TextStyle) -> Font {
        switch style {
        case .title:
            return .title.weight(.bold)
        case .headline:
            return .headline.weight(.semibold)
        case .subheadline:
            return .subheadline.weight(.medium)
        case .body:
            return .body
        case .caption:
            return .caption
        }
    }
}

// MARK: - Перечисления для UIManager

enum AppTheme: String, CaseIterable {
    case system = "Системная"
    case light = "Светлая"
    case dark = "Темная"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum DateFormatStyle {
    case short
    case medium
    case long
    case timeOnly
}

enum CardType {
    case summary
    case analytics
    case insights
}

enum TextStyle {
    case title
    case headline
    case subheadline
    case body
    case caption
}

// MARK: - Модификаторы для SwiftUI

struct CardModifier: ViewModifier {
    let type: CardType
    let uiManager: UIManager
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(uiManager.cardGradient(for: type))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .foregroundColor(.white)
    }
}

struct AnimatedTransactionModifier: ViewModifier {
    let type: TransactionType
    let uiManager: UIManager
    
    func body(content: Content) -> some View {
        content
            .animation(uiManager.transactionAnimation(for: type), value: type)
    }
}

// MARK: - Расширения для удобного использования

extension View {
    func financialCard(_ type: CardType, uiManager: UIManager) -> some View {
        self.modifier(CardModifier(type: type, uiManager: uiManager))
    }
    
    func withTransactionAnimation(_ type: TransactionType, uiManager: UIManager) -> some View {
        self.modifier(AnimatedTransactionModifier(type: type, uiManager: uiManager))
    }
}
