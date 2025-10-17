//
//  NotificationService.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // 通知権限をリクエスト
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

        // 権限が取得できたら、リモート通知登録
        if granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        return granted
    }

    // FCMトークンを登録（AppDelegate経由で呼ばれる）
    func registerDeviceToken(_ token: String) async {
        // Firestoreにデバイストークンを保存
        await FirebaseService.shared.saveDeviceToken(token)
        print("Device token registered: \(token)")
    }

    // 現在のFCMトークンを取得
    func getFCMToken() async -> String? {
        let token = Messaging.messaging().fcmToken
        return token
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
        // NOTE: Cloud Functionsでプッシュ通知を送信
        // Cloud FunctionがFirestoreで対象ユーザーのトークンを取得して
        // Firebase Admin SDKのメッセージング機能を使用して通知を送信
    }
}
