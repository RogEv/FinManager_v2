//
//  TransactionCategorizer.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation
import NaturalLanguage

class TransactionCategorizer {
    private let keywordClassifier: KeywordClassifier
    
    init() {
        self.keywordClassifier = KeywordClassifier()
    }
    
    func categorize(message: String) -> TransactionCategory {
        return keywordClassifier.categorize(message: message)
    }
}

class KeywordClassifier {
    private let categoryKeywords: [TransactionCategory: [String]]
    
    init() {
        self.categoryKeywords = [
            .food: [
                "lamoda.by", "det.tsentr", "kofe", "pekarnya", "konditer", "mak.by",
                "terr", "feroniya", "pizzerya", "restoran", "kafe", "stolovaya",
                "mcdonalds", "kfc", "burger", "sushi", "pirozhki", "bistro",
                "food", "eat", "coffee", "coffeetime", "питание", "еда", "кафе",
                "ресторан", "столовая", "бистро", "кофе", "пекарня", "кондитерская"
            ],
            .transportation: [
                "azs", "бензин", "заправка", "топливо", "парковка", "стоянка",
                "taxi", "yandex.taxi", "uber", "bolt", "avtobus", "metro",
                "tramvai", "zapravka", "benzokolonka", "parking", "stoanka",
                "такси", "автобус", "метро", "трамвай", "заправка", "бензоколонка"
            ],
            .shopping: [
                "shop", "magazin", "supermarket", "gipermarket", "universam",
                "odezhda", "obuv", "tekhnika", "electronics", "mebel", "apteka",
                "cosmetics", "parfymeriya", "21vek.by", "gippo", "oma", "fix price",
                "магазин", "супермаркет", "гипермаркет", "универсам", "одежда",
                "обувь", "техника", "электроника", "мебель", "аптека", "косметика"
            ],
            .bills: [
                "mobile bank", "mobile", "bank", "uslugi", "услуги", "банк",
                "мобильный", "связь", "интернет", "телефон", "коммунальные"
            ],
            .transfer: [
                "p2p", "perevod", "перевод", "p2p§sdbo", "p2p sdbo", "перечисление",
                "другому лицу", "межбанковский", "банковский перевод"
            ],
            .cash: [
                "nalichnye", "bankomat", "atm", "снятие", "наличные", "банкомат",
                "выдача наличных"
            ],
            .entertainment: [
                "music", "yandex music", "google", "подписка", "subscription",
                "развлечения", "кино", "театр", "концерт"
            ],
            .other: [
                "mojka", "мойка", "car wash", "автомойка", "химчистка"
            ]
        ]
    }
    
    func categorize(message: String) -> TransactionCategory {
        let lowercasedMessage = message.lowercased()
        
        // Специальные случаи
        if lowercasedMessage.contains("nalichnye") || lowercasedMessage.contains("bankomat") || lowercasedMessage.contains("atm") {
            return .transfer // Или можно создать отдельную категорию .cash
        }
        
        if lowercasedMessage.contains("mobile bank") {
            return .bills
        }
        
        if lowercasedMessage.contains("p2p") || lowercasedMessage.contains("perevod") {
            return .transfer
        }
        
        if lowercasedMessage.contains("zachisleno") {
            return .salary
        }
        
        // Проверяем по ключевым словам
        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: lowercasedMessage.contains) {
                return category
            }
        }
        
        return .other
    }
}
