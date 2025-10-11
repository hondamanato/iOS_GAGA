//
//  PhotoDetailView.swift
//  GAGA
//
//  Created by AI on 2025/10/11.
//

import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var user: User?
    @State private var country: Country?
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                photoView

                VStack(alignment: .leading, spacing: 12) {
                    actionButtonsView
                    captionView
                    locationView
                    timestampView
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadData()
        }
        .alert("写真を削除", isPresented: $showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                Task {
                    await deletePhoto()
                }
            }
        } message: {
            Text("この写真を削除してもよろしいですか？この操作は取り消せません。")
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 12) {
            // 戻るボタン
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }

            // プロフィール画像
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )

            // ユーザー名
            if let user = user {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.system(size: 14, weight: .semibold))
                    Text("@\(user.username)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }

            Spacer()

            // 3点メニュー（削除ボタン）
            if photo.userId == authManager.currentUser?.id {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(90))
                }
                .disabled(isDeleting)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var photoView: some View {
        CachedAsyncImage(url: photo.imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 400)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                VStack {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                    Text("画像の読み込みに失敗しました")
                        .foregroundColor(.secondary)
                }
                .frame(height: 400)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
            @unknown default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // いいねボタン
            Button {
                // TODO: いいね機能を実装
            } label: {
                Image(systemName: "heart")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }

            // コメントボタン
            Button {
                // TODO: コメント機能を実装
            } label: {
                Image(systemName: "bubble.left")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }

            // シェアボタン
            Button {
                // TODO: シェア機能を実装
            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }

            Spacer()

            // 保存ボタン
            Button {
                // TODO: 保存機能を実装
            } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var captionView: some View {
        if let user = user {
            HStack(alignment: .top, spacing: 4) {
                // ユーザー名（太字）
                Text(user.username)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)

                // キャプション
                if let caption = photo.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                } else {
                    Text("")
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var locationView: some View {
        if let country = country {
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                Text(country.nameJa ?? country.name)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
            }
        }
    }

    @ViewBuilder
    private var timestampView: some View {
        Text(formatRelativeDate(photo.createdAt))
            .font(.system(size: 12))
            .foregroundColor(.secondary)
    }

    private func loadData() async {
        isLoading = true

        // ユーザー情報を取得
        do {
            let fetchedUser = try await FirebaseService.shared.getUser(userId: photo.userId)
            await MainActor.run {
                self.user = fetchedUser
            }
        } catch {
            print("❌ Failed to load user: \(error)")
        }

        // 国情報を取得
        let allCountries = GeoDataManager.shared.getAllCountries()
        if let foundCountry = allCountries.first(where: { $0.id == photo.countryCode }) {
            await MainActor.run {
                self.country = foundCountry
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func deletePhoto() async {
        isDeleting = true

        do {
            // Firestoreから写真を削除
            try await FirebaseService.shared.deletePhoto(photoId: photo.id)

            // Storage から画像を削除（StorageServiceを使用）
            // TODO: StorageServiceに削除メソッドを追加する必要がある場合

            // ユーザーの訪問国リストから削除（その国の写真が他にない場合）
            if let currentUserId = authManager.currentUser?.id {
                let userPhotos = try await FirebaseService.shared.getPhotos(for: currentUserId)
                let photosInCountry = userPhotos.filter { $0.countryCode == photo.countryCode }

                // この国の写真がこれだけなら、訪問国リストから削除
                if photosInCountry.count == 1 && photosInCountry.first?.id == photo.id {
                    // TODO: visitedCountriesから削除するメソッドを実装
                    print("ℹ️ Last photo in \(photo.countryCode), should remove from visited countries")
                }
            }

            print("✅ Photo deleted successfully")

            // 画面を閉じる
            await MainActor.run {
                dismiss()
            }

            // 削除成功を親ビューに通知（親が写真リストを再読み込み）
            await MainActor.run {
                onDelete?()
            }

        } catch {
            print("❌ Failed to delete photo: \(error)")
            await MainActor.run {
                isDeleting = false
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date, to: now)

        if let years = components.year, years > 0 {
            return "\(years)年前"
        } else if let months = components.month, months > 0 {
            return "\(months)ヶ月前"
        } else if let days = components.day, days > 0 {
            return "\(days)日前"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)時間前"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分前"
        } else {
            return "たった今"
        }
    }
}

#Preview {
    PhotoDetailView(photo: Photo(
        userId: "test-user-id",
        countryCode: "JP",
        imageURL: "https://via.placeholder.com/400",
        thumbnailURL: "https://via.placeholder.com/200"
    ))
}
