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

    // いいね・保存の状態
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var likeCount: Int
    @State private var isLiking = false
    @State private var isBookmarking = false

    // コメント・シェア
    @State private var showCommentView = false
    @State private var showShareSheet = false

    init(photo: Photo, onDelete: (() -> Void)? = nil) {
        self.photo = photo
        self.onDelete = onDelete
        _likeCount = State(initialValue: photo.likeCount)
    }

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
        .sheet(isPresented: $showShareSheet) {
            if let url = URL(string: photo.imageURL) {
                ShareSheet(items: [url, photo.caption ?? ""])
            }
        }
        .sheet(isPresented: $showCommentView) {
            CommentView(photo: photo)
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

            // プロフィール画像とユーザー名（タップでプロフィールへ）
            if let user = user {
                NavigationLink(destination: UserDetailView(user: user)) {
                    HStack(spacing: 12) {
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                            Text("@\(user.username)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )

                    ProgressView()
                        .scaleEffect(0.8)
                }
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
                Task {
                    await toggleLike()
                }
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 24))
                    .foregroundColor(isLiked ? .red : .black)
            }
            .disabled(isLiking)

            // コメントボタン
            Button {
                showCommentView = true
            } label: {
                Image(systemName: "bubble.left")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }

            // シェアボタン
            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }

            Spacer()

            // 保存ボタン
            Button {
                Task {
                    await toggleBookmark()
                }
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
            .disabled(isBookmarking)
        }
        .padding(.top, 8)

        // いいね数表示
        if likeCount > 0 {
            Text("\(likeCount)人がいいねしました")
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 8)
        }
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

        // いいね・保存状態をチェック
        if let currentUserId = authManager.currentUser?.id {
            do {
                let liked = try await PhotoInteractionService.shared.checkIfLiked(photoId: photo.id, userId: currentUserId)
                let bookmarked = try await PhotoInteractionService.shared.checkIfBookmarked(photoId: photo.id, userId: currentUserId)

                await MainActor.run {
                    self.isLiked = liked
                    self.isBookmarked = bookmarked
                }
            } catch {
                print("❌ Failed to check interaction status: \(error)")
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    // MARK: - Interaction Functions

    private func toggleLike() async {
        guard let currentUserId = authManager.currentUser?.id else { return }
        guard !isLiking else { return }

        isLiking = true

        do {
            if isLiked {
                try await PhotoInteractionService.shared.unlikePhoto(photoId: photo.id, userId: currentUserId)
                await MainActor.run {
                    self.isLiked = false
                    self.likeCount = max(0, likeCount - 1)
                }
            } else {
                try await PhotoInteractionService.shared.likePhoto(photoId: photo.id, userId: currentUserId)
                await MainActor.run {
                    self.isLiked = true
                    self.likeCount += 1
                }
            }
        } catch {
            print("❌ Failed to toggle like: \(error)")
        }

        await MainActor.run {
            isLiking = false
        }
    }

    private func toggleBookmark() async {
        guard let currentUserId = authManager.currentUser?.id else { return }
        guard !isBookmarking else { return }

        isBookmarking = true

        do {
            if isBookmarked {
                try await PhotoInteractionService.shared.unbookmarkPhoto(photoId: photo.id, userId: currentUserId)
                await MainActor.run {
                    self.isBookmarked = false
                }
            } else {
                try await PhotoInteractionService.shared.bookmarkPhoto(photoId: photo.id, userId: currentUserId)
                await MainActor.run {
                    self.isBookmarked = true
                }
            }
        } catch {
            print("❌ Failed to toggle bookmark: \(error)")
        }

        await MainActor.run {
            isBookmarking = false
        }
    }

    // MARK: - Delete Function

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

            // 削除成功を親ビューに通知（親が写真リストを再読み込み）
            // 注: dismiss()の前に実行して、確実に更新処理をトリガーする
            await MainActor.run {
                onDelete?()
            }

            // 少し待機してから画面を閉じる（更新処理が開始されるのを待つ）
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

            // 画面を閉じる
            await MainActor.run {
                dismiss()
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

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
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
