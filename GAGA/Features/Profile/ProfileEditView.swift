//
//  ProfileEditView.swift
//  GAGA
//
//  Created by AI on 2025/10/11.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploading = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCheckingUsername = false
    @State private var usernameError: String?
    @State private var originalUsername: String = ""

    var body: some View {
        Form {
            // プロフィール画像セクション
            Section {
                VStack(spacing: 16) {
                    // プロフィール画像
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            )
                    }

                    // 写真選択ボタン
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        Text("写真を選択")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedImage) { oldValue, newValue in
                        Task {
                            await loadSelectedImage()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // ユーザー情報セクション
            Section("ユーザー情報") {
                HStack {
                    Text("表示名")
                    TextField("表示名を入力", text: $displayName)
                        .multilineTextAlignment(.trailing)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ユーザーネーム")
                        Spacer()
                        TextField("username", text: $username)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .onChange(of: username) { oldValue, newValue in
                                Task {
                                    await validateUsername(newValue)
                                }
                            }

                        if isCheckingUsername {
                            ProgressView()
                                .frame(width: 16, height: 16)
                        } else if username != originalUsername && !username.isEmpty && usernameError == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.black)
                                .font(.caption)
                        }
                    }

                    if let error = usernameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if username != originalUsername && !username.isEmpty {
                        Text("使用可能です")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Text("3-20文字、英小文字・数字・._-のみ")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let email = authManager.currentUser?.email {
                    HStack {
                        Text("メールアドレス")
                        Spacer()
                        Text(email)
                            .foregroundColor(.secondary)
                    }
                }

                NavigationLink(destination: PasswordChangeView()) {
                    HStack {
                        Text("パスワードを変更")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            }

            // 統計情報（読み取り専用）
            if let user = authManager.currentUser {
                Section("統計") {
                    HStack {
                        Text("訪問した国")
                        Spacer()
                        Text("\(user.visitedCountries.count)カ国")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("フォロワー")
                        Spacer()
                        Text("\(user.followerCount)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("フォロー中")
                        Spacer()
                        Text("\(user.followingCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    Task {
                        await saveProfile()
                    }
                }
                .disabled(isSaving || displayName.isEmpty || username.isEmpty || usernameError != nil)
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isSaving || isUploading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(isUploading ? "画像をアップロード中..." : "保存中...")
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
        }
    }

    private func loadCurrentProfile() {
        guard let user = authManager.currentUser else { return }
        displayName = user.displayName
        username = user.username
        originalUsername = user.username

        // プロフィール画像を読み込む
        if let imageURL = user.profileImageURL {
            Task {
                await loadProfileImage(from: imageURL)
            }
        }
    }

    private func loadProfileImage(from urlString: String) async {
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                }
            }
        } catch {
            print("❌ Failed to load profile image: \(error)")
        }
    }

    private func loadSelectedImage() async {
        guard let selectedImage = selectedImage else { return }

        do {
            if let data = try await selectedImage.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                }
            }
        } catch {
            print("❌ Failed to load selected image: \(error)")
            await MainActor.run {
                errorMessage = "画像の読み込みに失敗しました"
                showError = true
            }
        }
    }

    private func saveProfile() async {
        guard var user = authManager.currentUser else { return }

        isSaving = true

        do {
            // プロフィール画像がある場合はアップロード
            if let profileImage = profileImage, user.profileImageURL == nil || selectedImage != nil {
                isUploading = true
                let imageURL = try await uploadProfileImage(image: profileImage, userId: user.id)
                user.profileImageURL = imageURL
                isUploading = false
            }

            // ユーザーネームが変更された場合は更新
            if username != originalUsername {
                try await FirebaseService.shared.updateUsername(
                    oldUsername: originalUsername,
                    newUsername: username,
                    userId: user.id
                )
            }

            // ユーザー情報を更新
            user.displayName = displayName
            user.username = username
            user.updatedAt = Date()

            // Firestoreに保存
            try await FirebaseService.shared.saveUser(user)

            // AuthManagerを更新
            await MainActor.run {
                authManager.currentUser = user
                isSaving = false
                dismiss()
            }

            print("✅ Profile updated successfully")
        } catch {
            print("❌ Failed to save profile: \(error)")
            await MainActor.run {
                isSaving = false
                isUploading = false
                errorMessage = "プロフィールの保存に失敗しました: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    // ユーザーネームのバリデーション
    private func validateUsername(_ value: String) async {
        // 空の場合はスキップ
        guard !value.isEmpty else {
            usernameError = nil
            return
        }

        // 元のユーザーネームと同じ場合はOK
        if value.lowercased() == originalUsername.lowercased() {
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

    private func uploadProfileImage(image: UIImage, userId: String) async throws -> String {
        // 画像をリサイズ（最大800x800）
        let resizedImage = image.resized(to: CGSize(width: 800, height: 800))

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProfileEditView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }

        // Firebase Storageにアップロード
        let path = "profile_images/\(userId)/profile.jpg"
        let imageURL = try await StorageService.shared.uploadImage(imageData, path: path)

        return imageURL
    }
}

// MARK: - UIImage Extension for Resizing
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    NavigationView {
        ProfileEditView()
    }
}
