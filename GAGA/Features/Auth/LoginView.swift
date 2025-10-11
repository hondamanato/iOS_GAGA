//
//  LoginView.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var username = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSignUpMode = false
    @State private var isCheckingUsername = false
    @State private var usernameError: String?

    var body: some View {
        VStack(spacing: 20) {
            // ロゴ
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 80))
                .foregroundColor(.black)

            Text("GAGA")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("旅行の思い出を3D地球儀に")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
                .frame(height: 40)

            // Apple ID サインイン
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]

                    // nonceを生成してリクエストに設定
                    let (_, hashedNonce) = authManager.generateNonce()
                    request.nonce = hashedNonce
                },
                onCompletion: { result in
                    Task {
                        await handleAppleSignIn(result)
                    }
                }
            )
            .frame(height: 50)
            .cornerRadius(10)

            Text("または")
                .foregroundColor(.secondary)

            // メールアドレスログイン/新規登録
            VStack(spacing: 12) {
                if isSignUpMode {
                    TextField("表示名", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.name)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("ユーザーネーム", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .onChange(of: username) { oldValue, newValue in
                                    Task {
                                        await validateUsername(newValue)
                                    }
                                }

                            if isCheckingUsername {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            } else if !username.isEmpty && usernameError == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.black)
                            }
                        }

                        if let error = usernameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if !username.isEmpty {
                            Text("使用可能です")
                                .font(.caption)
                                .foregroundColor(.green)
                        }

                        Text("3-20文字、英小文字・数字・._-のみ")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                TextField("メールアドレス", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("パスワード", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)

                Button(action: {
                    Task {
                        if isSignUpMode {
                            await emailSignUp()
                        } else {
                            await emailSignIn()
                        }
                    }
                }) {
                    Text(isSignUpMode ? "新規登録" : "ログイン")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    isSignUpMode.toggle()
                    errorMessage = ""
                }) {
                    Text(isSignUpMode ? "既にアカウントをお持ちの方" : "アカウントをお持ちでない方")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }

            Spacer()
        }
        .padding()
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                do {
                    try await authManager.signInWithApple(authorization)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func emailSignIn() async {
        do {
            try await authManager.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func emailSignUp() async {
        // バリデーション
        guard !displayName.isEmpty else {
            errorMessage = "表示名を入力してください"
            showError = true
            return
        }

        guard !username.isEmpty else {
            errorMessage = "ユーザーネームを入力してください"
            showError = true
            return
        }

        guard usernameError == nil else {
            errorMessage = usernameError ?? "ユーザーネームが無効です"
            showError = true
            return
        }

        guard !email.isEmpty else {
            errorMessage = "メールアドレスを入力してください"
            showError = true
            return
        }

        guard password.count >= 6 else {
            errorMessage = "パスワードは6文字以上で設定してください"
            showError = true
            return
        }

        do {
            try await authManager.signUp(email: email, password: password, displayName: displayName, username: username)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // ユーザーネームのバリデーション
    private func validateUsername(_ value: String) async {
        // 空の場合はスキップ
        guard !value.isEmpty else {
            usernameError = nil
            return
        }

        isCheckingUsername = true

        // フォーマットチェック
        let normalizedUsername = value.lowercased()
        let pattern = "^[a-z0-9][a-z0-9._-]{1,18}[a-z0-9]$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: normalizedUsername.utf16.count)

        guard regex?.firstMatch(in: normalizedUsername, range: range) != nil else {
            usernameError = "3-20文字、英小文字・数字・._-のみ使用可能です"
            isCheckingUsername = false
            return
        }

        // 連続するピリオドをチェック
        if normalizedUsername.contains("..") {
            usernameError = "連続するピリオドは使用できません"
            isCheckingUsername = false
            return
        }

        // 重複チェック
        do {
            let isAvailable = try await FirebaseService.shared.checkUsernameAvailability(normalizedUsername)
            if isAvailable {
                usernameError = nil
            } else {
                usernameError = "このユーザーネームは既に使用されています"
            }
        } catch {
            usernameError = "チェック中にエラーが発生しました"
        }

        isCheckingUsername = false
    }
}

#Preview {
    LoginView()
}
