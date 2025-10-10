//
//  AuthManager.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private init() {
        checkAuthState()
    }

    // 認証状態チェック
    func checkAuthState() {
        // テスト用: 自動的にダミーユーザーでログイン
        let testUserId = UserDefaults.standard.string(forKey: "testUserId") ?? {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "testUserId")
            return newId
        }()

        let testUser = User(
            id: testUserId,
            displayName: "テストユーザー",
            email: "test@example.com"
        )

        currentUser = testUser
        isAuthenticated = true

        print("✅ Test user authenticated: \(testUserId)")
    }

    // メールアドレスでサインイン
    func signIn(email: String, password: String) async throws {
        // TODO: Firebase Authentication実装
        // try await Auth.auth().signIn(withEmail: email, password: password)

        // 仮のユーザー作成
        let user = User(id: UUID().uuidString, displayName: "Test User", email: email)
        currentUser = user
        isAuthenticated = true
    }

    // Apple IDでサインイン
    func signInWithApple(_ authorization: ASAuthorization) async throws {
        // TODO: Firebase AuthenticationでApple IDサインイン実装

        // 仮のユーザー作成
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userId = credential.user
            let email = credential.email ?? ""
            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            let user = User(id: userId, displayName: displayName.isEmpty ? "Apple User" : displayName, email: email)
            currentUser = user
            isAuthenticated = true
        }
    }

    // 新規登録
    func signUp(email: String, password: String, displayName: String) async throws {
        // TODO: Firebase Authenticationで新規登録

        let user = User(id: UUID().uuidString, displayName: displayName, email: email)
        currentUser = user
        isAuthenticated = true
    }

    // サインアウト
    func signOut() throws {
        // TODO: Firebase Authenticationでサインアウト
        currentUser = nil
        isAuthenticated = false
    }
}
