//
//  CommentView.swift
//  GAGA
//
//  Created by AI on 2025/10/12.
//

import SwiftUI

struct CommentView: View {
    let photo: Photo
    var onCommentAdded: (() -> Void)? = nil
    var initialComments: [Comment] = []  // 初期コメント（キャッシュ用）

    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var commentText = ""
    @State private var comments: [Comment] = []
    @State private var isLoading: Bool
    @State private var isPosting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isDeleting: Set<String> = []
    @State private var commentToDelete: Comment?
    @State private var showDeleteConfirmation = false

    init(photo: Photo, onCommentAdded: (() -> Void)? = nil, initialComments: [Comment] = []) {
        self.photo = photo
        self.onCommentAdded = onCommentAdded
        self.initialComments = initialComments
        // 初期コメントがある場合はローディング表示をしない
        self._isLoading = State(initialValue: initialComments.isEmpty)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // コメントリスト
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("まだコメントがありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("最初のコメントを投稿しましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(comments) { comment in
                                CommentRow(
                                    comment: comment,
                                    canDelete: comment.userId == authManager.currentUser?.id || photo.userId == authManager.currentUser?.id,
                                    isDeleting: isDeleting.contains(comment.id),
                                    onDelete: {
                                        commentToDelete = comment
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                // コメント入力欄
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )

                    TextField("コメントを追加...", text: $commentText)
                        .textFieldStyle(.plain)

                    Button {
                        Task {
                            await postComment()
                        }
                    } label: {
                        Text("投稿")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(commentText.isEmpty ? .gray : .blue)
                    }
                    .disabled(commentText.isEmpty || isPosting)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("コメント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .task {
                // 初期コメントがあれば一時的に表示（高速化のため）
                if !initialComments.isEmpty {
                    await MainActor.run {
                        self.comments = initialComments
                        self.isLoading = false
                    }
                    print("✅ Using cached comments: \(initialComments.count)")
                }

                // 常に最新のコメントを Firestore から取得（バックグラウンドで）
                await loadComments()
            }
            .alert("エラー", isPresented: $showError) {
                Button("キャンセル", role: .cancel) { }
                Button("もう一度試す") {
                    Task {
                        await loadComments()
                    }
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("コメントを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    if let comment = commentToDelete {
                        Task {
                            await deleteComment(comment)
                        }
                    }
                }
            } message: {
                Text("このコメントを削除してもよろしいですか？")
            }
        }
    }

    private func loadComments() async {
        // 初期コメントがある場合はローディング表示をしない（すでに表示されているため）
        if initialComments.isEmpty {
            isLoading = true
        }

        do {
            let loadedComments = try await FirebaseService.shared.getComments(for: photo.id)

            await MainActor.run {
                // 重複を防ぐため、IDでユニークなコメントのみを保持
                var uniqueComments: [Comment] = []
                var seenIds: Set<String> = []

                for comment in loadedComments {
                    if !seenIds.contains(comment.id) {
                        uniqueComments.append(comment)
                        seenIds.insert(comment.id)
                    }
                }

                self.comments = uniqueComments
                self.isLoading = false
                self.errorMessage = nil
                self.showError = false
            }

            print("✅ Loaded \(loadedComments.count) comments for photo \(photo.id)")
        } catch {
            print("❌ Failed to load comments: \(error)")

            // ネットワークエラーの場合はリトライ可能にする
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "コメントの読み込みに失敗しました。しばらくしてからもう一度お試しください。"
                self.showError = true
            }
        }
    }

    private func postComment() async {
        guard !commentText.isEmpty else { return }
        guard let currentUser = authManager.currentUser else {
            await MainActor.run {
                errorMessage = "ログインが必要です"
                showError = true
            }
            return
        }

        let textToPost = commentText

        await MainActor.run {
            commentText = ""
            isPosting = true
        }

        do {
            let newComment = try await FirebaseService.shared.postComment(
                photoId: photo.id,
                userId: currentUser.id,
                username: currentUser.username,
                text: textToPost
            )

            await MainActor.run {
                // 重複を防ぐため、同じIDのコメントがないか確認
                if !self.comments.contains(where: { $0.id == newComment.id }) {
                    self.comments.insert(newComment, at: 0) // 最新コメントを上に追加
                }
                self.isPosting = false
            }

            // 親ビューに通知
            onCommentAdded?()

            print("✅ Comment posted successfully")
        } catch {
            print("❌ Failed to post comment: \(error)")

            await MainActor.run {
                self.commentText = textToPost
                self.isPosting = false
                self.errorMessage = "コメントの投稿に失敗しました"
                self.showError = true
            }
        }
    }

    private func deleteComment(_ comment: Comment) async {
        guard !isDeleting.contains(comment.id) else { return }

        await MainActor.run {
            isDeleting.insert(comment.id)
        }

        do {
            try await FirebaseService.shared.deleteComment(commentId: comment.id, photoId: photo.id)

            await MainActor.run {
                // コメントをリストから削除
                self.comments.removeAll { $0.id == comment.id }
                self.isDeleting.remove(comment.id)
                self.commentToDelete = nil
            }

            print("✅ Comment deleted successfully")
        } catch {
            print("❌ Failed to delete comment: \(error)")

            await MainActor.run {
                self.isDeleting.remove(comment.id)
                self.errorMessage = "コメントの削除に失敗しました"
                self.showError = true
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let canDelete: Bool
    let isDeleting: Bool
    let onDelete: () -> Void
    @State private var user: User?
    @State private var isLoadingUser = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // プロフィール画像
            if let user = user, let profileImageURL = user.profileImageURL {
                CachedAsyncImage(url: profileImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            )
                    default:
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            )
                    }
                }
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                // ユーザー名とコメント
                HStack(alignment: .top) {
                    Text(comment.username)
                        .font(.system(size: 14, weight: .semibold))

                    Text(comment.text)
                        .font(.system(size: 14))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 投稿時間
                Text(formatDate(comment.createdAt ?? Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 削除ボタン（権限がある場合）
            if canDelete {
                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .disabled(isDeleting)
                .opacity(isDeleting ? 0.5 : 1.0)
            }
        }
        .opacity(isDeleting ? 0.5 : 1.0)
        .task {
            await loadUser()
        }
    }

    private func loadUser() async {
        guard user == nil && !isLoadingUser else { return }

        isLoadingUser = true

        do {
            let fetchedUser = try await FirebaseService.shared.getUser(userId: comment.userId)
            await MainActor.run {
                self.user = fetchedUser
            }
        } catch {
            print("❌ Failed to load user for comment: \(error)")
        }

        await MainActor.run {
            isLoadingUser = false
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Comment Model

struct Comment: Identifiable, Codable {
    var id: String
    let photoId: String
    let userId: String
    let username: String
    let text: String
    let createdAt: Date?

    init(id: String = UUID().uuidString, photoId: String, userId: String, username: String, text: String, createdAt: Date? = nil) {
        self.id = id
        self.photoId = photoId
        self.userId = userId
        self.username = username
        self.text = text
        self.createdAt = createdAt ?? Date()
    }
}

#Preview {
    CommentView(photo: Photo(
        userId: "test-user-id",
        countryCode: "JP",
        imageURL: "https://via.placeholder.com/400",
        thumbnailURL: "https://via.placeholder.com/200"
    ))
}
