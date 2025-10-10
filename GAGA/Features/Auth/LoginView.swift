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
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            // ロゴ
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

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

            // メールアドレスログイン
            VStack(spacing: 12) {
                TextField("メールアドレス", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("パスワード", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)

                Button(action: {
                    Task {
                        await emailSignIn()
                    }
                }) {
                    Text("ログイン")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
}

#Preview {
    LoginView()
}
