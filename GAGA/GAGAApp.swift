//
//  GAGAApp.swift
//  GAGA
//
//  Created by 本多真翔 on 2025/10/09.
//

import SwiftUI
import FirebaseCore

// AppDelegate for Firebase initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
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
