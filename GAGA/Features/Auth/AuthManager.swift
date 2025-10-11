//
//  AuthManager.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import AuthenticationServices
import FirebaseAuth
import CryptoKit

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    private init() {
        checkAuthState()
    }

    // 認証状態チェック・リスナー設定
    func checkAuthState() {
        // Firebase Authの認証状態をリスニング
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    print("✅ Firebase user authenticated: \(firebaseUser.uid)")

                    // Firestoreからユーザー情報を取得
                    do {
                        let user = try await FirebaseService.shared.getUser(userId: firebaseUser.uid)
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        print("✅ User data loaded from Firestore")
                    } catch {
                        print("⚠️ User not found in Firestore, creating new user")

                        // Firestoreにユーザーが存在しない場合は作成
                        // ユーザーネームを自動生成（uidの最初の8文字）
                        let autoUsername = String(firebaseUser.uid.prefix(8).lowercased())

                        let newUser = User(
                            id: firebaseUser.uid,
                            displayName: firebaseUser.displayName ?? "ユーザー",
                            username: autoUsername,
                            email: firebaseUser.email
                        )

                        // ユーザーネームを予約
                        try? await FirebaseService.shared.reserveUsername(autoUsername, userId: firebaseUser.uid)
                        try? await FirebaseService.shared.saveUser(newUser)
                        self?.currentUser = newUser
                        self?.isAuthenticated = true
                    }
                } else {
                    print("ℹ️ No authenticated user")
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }

    // メールアドレスでサインイン
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ Signed in with email: \(result.user.email ?? "")")
            // 認証状態リスナーが自動的にユーザー情報を更新
        } catch {
            print("❌ Sign in error: \(error.localizedDescription)")
            throw AuthError.from(error)
        }
    }

    // Apple IDでサインイン（nonceを使用）
    func signInWithApple(_ authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        // 保存されたnonceを取得
        guard let nonce = currentNonce else {
            print("❌ No nonce found")
            throw AuthError.invalidCredential
        }

        // Firebase用のOAuthクレデンシャルを作成（nonceを指定）
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        do {
            let result = try await Auth.auth().signIn(with: credential)
            print("✅ Signed in with Apple ID: \(result.user.uid)")

            // 初回ログインの場合、displayNameとusernameを更新
            if let fullName = appleIDCredential.fullName,
               let givenName = fullName.givenName,
               let familyName = fullName.familyName {
                let displayName = "\(familyName) \(givenName)"

                // Firebase Authのプロフィールを更新
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()

                // Firestoreのユーザー情報も更新
                if var user = currentUser {
                    user.displayName = displayName
                    // Apple Sign Inの場合、初回のみusernameを自動生成
                    if user.username.count == 8 && user.username == String(user.id.prefix(8).lowercased()) {
                        // 自動生成されたユーザーネームの場合は更新可能
                    }
                    try await FirebaseService.shared.saveUser(user)
                }
            }

            // 認証状態リスナーが自動的にユーザー情報を更新
        } catch {
            print("❌ Apple Sign in error: \(error.localizedDescription)")
            throw AuthError.from(error)
        }
    }

    // 新規登録
    func signUp(email: String, password: String, displayName: String, username: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ User created: \(result.user.uid)")

            // ユーザーネームを予約
            try await FirebaseService.shared.reserveUsername(username, userId: result.user.uid)

            // displayNameを設定
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            // Firestoreにユーザー情報を保存
            let newUser = User(
                id: result.user.uid,
                displayName: displayName,
                username: username,
                email: email
            )
            try await FirebaseService.shared.saveUser(newUser)

            // 認証状態リスナーが自動的にユーザー情報を更新
        } catch {
            print("❌ Sign up error: \(error.localizedDescription)")
            throw AuthError.from(error)
        }
    }

    // サインアウト
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            print("✅ Signed out successfully")
            // 認証状態リスナーが自動的にユーザー情報をクリア
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
            throw AuthError.from(error)
        }
    }

    // MARK: - Apple Sign In用のNonce生成

    /// ランダムなnonceを生成してSHA256ハッシュ化する
    /// - Returns: (元のnonce, SHA256ハッシュ化されたnonce)
    func generateNonce() -> (nonce: String, hashedNonce: String) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let hashedNonce = sha256(nonce)
        return (nonce, hashedNonce)
    }

    /// ランダムな32文字のnonce文字列を生成
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    /// 文字列をSHA256でハッシュ化
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}

// MARK: - エラーハンドリング

enum AuthError: LocalizedError {
    case invalidCredential
    case emailAlreadyInUse
    case weakPassword
    case userNotFound
    case wrongPassword
    case invalidEmail
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "認証情報が無効です"
        case .emailAlreadyInUse:
            return "このメールアドレスは既に使用されています"
        case .weakPassword:
            return "パスワードは6文字以上で設定してください"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .wrongPassword:
            return "パスワードが間違っています"
        case .invalidEmail:
            return "メールアドレスの形式が正しくありません"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknown(let message):
            return message
        }
    }

    static func from(_ error: Error) -> AuthError {
        let nsError = error as NSError

        // Firebase Authのエラーコードを日本語エラーに変換
        guard nsError.domain == "FIRAuthErrorDomain" else {
            return .unknown(error.localizedDescription)
        }

        // NSErrorのコードをAuthErrorCodeに変換
        guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(error.localizedDescription)
        }

        switch errorCode {
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .wrongPassword
        case .invalidEmail:
            return .invalidEmail
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
