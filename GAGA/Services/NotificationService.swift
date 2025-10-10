//
//  NotificationService.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // 通知権限をリクエスト
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }

    // デバイストークンを登録
    func registerDeviceToken(_ token: Data) async throws {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()

        // TODO: Firestoreにデバイストークンを保存
        // TODO: Firebase Cloud Messagingに登録
        print("Device token: \(tokenString)")
    }

    // ローカル通知を送信
    func sendLocalNotification(title: String, body: String, delay: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    // プッシュ通知を送信（サーバー側で実装）
    func sendPushNotification(to userId: String, title: String, body: String) async throws {
        // TODO: Cloud Functionsでプッシュ通知を送信
    }
}
