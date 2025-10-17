//
//  GAGAApp.swift
//  GAGA
//
//  Created by 本多真翔 on 2025/10/09.
//

import SwiftUI
import FirebaseCore
import UserNotifications
import FirebaseMessaging

// AppDelegate for Firebase initialization and push notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // プッシュ通知のデリゲート設定
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        return true
    }

    // リモート通知登録成功時
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Firebase Cloud Messagingが自動的にAPNSトークンを設定
        Messaging.messaging().apnsToken = deviceToken
    }

    // リモート通知登録失敗時
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // フォアグラウンドで通知を受け取った時
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        // 通知をコンソールに出力
        print("Received notification in foreground: \(userInfo)")

        // バッジ、サウンド、バナーを表示
        completionHandler([.banner, .sound, .badge])
    }

    // ユーザーが通知をタップした時
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // 通知データを処理
        if let photoId = userInfo["photoId"] as? String {
            // 写真詳細画面に遷移するなどの処理を追加可能
            print("Tapped notification for photo: \(photoId)")
        }

        if let userId = userInfo["userId"] as? String {
            // プロフィール画面に遷移するなどの処理を追加可能
            print("Tapped notification for user: \(userId)")
        }

        completionHandler()
    }

    // FCMトークン更新時
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "No token")")

        // トークンをFirestoreに保存
        if let fcmToken = fcmToken {
            Task {
                await NotificationService.shared.registerDeviceToken(fcmToken)
            }
        }
    }
}

@main
struct GAGAApp: App {
    // Register AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
