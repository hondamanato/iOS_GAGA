//
//  PasswordChangeView.swift
//  GAGA
//
//  Created by AI on 2025/10/11.
//

import SwiftUI
import FirebaseAuth

struct PasswordChangeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChanging = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            // 現在のパスワード
            Section {
                SecureField("現在のパスワード", text: $currentPassword)
                    .textContentType(.password)
            } header: {
                Text("現在のパスワード")
            } footer: {
                Text("確認のため、現在のパスワードを入力してください")
                    .font(.caption)
            }

            // 新しいパスワード
            Section {
                SecureField("新しいパスワード", text: $newPassword)
                    .textContentType(.newPassword)

                SecureField("新しいパスワード（確認）", text: $confirmPassword)
                    .textContentType(.newPassword)
            } header: {
                Text("新しいパスワード")
            } footer: {
                Text("パスワードは6文字以上で設定してください")
                    .font(.caption)
            }

            // パスワード強度インジケーター
            if !newPassword.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: newPassword.count >= 6 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(newPassword.count >= 6 ? .green : .red)
                            Text("6文字以上")
                                .font(.caption)
                        }

                        HStack {
                            Image(systemName: newPassword == confirmPassword && !confirmPassword.isEmpty ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(newPassword == confirmPassword && !confirmPassword.isEmpty ? .green : .red)
                            Text("パスワードが一致")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("パスワード要件")
                }
            }

            // 変更ボタン
            Section {
                Button(action: {
                    Task {
                        await changePassword()
                    }
                }) {
                    if isChanging {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("パスワードを変更")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
                .disabled(isChanging || !isFormValid)
            }
        }
        .navigationTitle("パスワード変更")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("成功", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("パスワードを変更しました")
        }
    }

    // フォームのバリデーション
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    // パスワード変更処理
    private func changePassword() async {
        isChanging = true

        do {
            // 現在のユーザーを取得
            guard let user = Auth.auth().currentUser,
                  let email = user.email else {
                errorMessage = "ユーザー情報を取得できませんでした"
                showError = true
                isChanging = false
                return
            }

            // 再認証（セキュリティのため、現在のパスワードで確認）
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)

            // パスワードを変更
            try await user.updatePassword(to: newPassword)

            // 成功
            await MainActor.run {
                isChanging = false
                showSuccess = true
            }

            print("✅ Password changed successfully")
        } catch let error as NSError {
            await MainActor.run {
                isChanging = false

                // エラーメッセージを日本語化
                switch error.code {
                case AuthErrorCode.wrongPassword.rawValue:
                    errorMessage = "現在のパスワードが正しくありません"
                case AuthErrorCode.weakPassword.rawValue:
                    errorMessage = "パスワードが弱すぎます。6文字以上で設定してください"
                case AuthErrorCode.requiresRecentLogin.rawValue:
                    errorMessage = "セキュリティのため、再度ログインしてください"
                case AuthErrorCode.networkError.rawValue:
                    errorMessage = "ネットワークエラーが発生しました"
                default:
                    errorMessage = "パスワードの変更に失敗しました: \(error.localizedDescription)"
                }

                showError = true
            }

            print("❌ Failed to change password: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        PasswordChangeView()
    }
}
