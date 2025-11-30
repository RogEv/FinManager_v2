//
//  PermissionManager.swift
//  FinManager_v2
//
//  Created by Evgeni Rozkov on 29.11.25.
//

import Foundation
import MessageUI
import UserNotifications

class PermissionManager: ObservableObject {
    @Published var hasSMSPermission = false
    
    func requestSMSPermission() {
        // На iOS 14+ прямой доступ к SMS ограничен
        // Альтернативные подходы:
        // 1. Ручной ввод SMS
        // 2. Использование банковских API
        // 3. Фильтры сообщений (требует разрешения пользователя)
    }
}
