//
//  CommentView.swift
//  GAGA
//
//  Created by AI on 2025/10/12.
//

import SwiftUI

struct CommentView: View {
    let photo: Photo
    @Environment(\.dismiss) var dismiss
    @State private var commentText = ""
    @State private var comments: [Comment] = []
    @State private var isLoading = true
    @State private var isPosting = false

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
                                CommentRow(comment: comment)
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
                await loadComments()
            }
        }
    }

    private func loadComments() async {
        // TODO: Firestoreからコメントを読み込み
        isLoading = false
    }

    private func postComment() async {
        guard !commentText.isEmpty else { return }

        isPosting = true

        // TODO: Firestoreにコメントを投稿

        commentText = ""
        isPosting = false
    }
}

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // プロフィール画像
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )

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
                Text(formatDate(comment.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
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
    let id: String
    let photoId: String
    let userId: String
    let username: String
    let text: String
    let createdAt: Date

    init(id: String = UUID().uuidString, photoId: String, userId: String, username: String, text: String, createdAt: Date = Date()) {
        self.id = id
        self.photoId = photoId
        self.userId = userId
        self.username = username
        self.text = text
        self.createdAt = createdAt
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
