//
//  NotificationListView.swift
//  GAGA
//
//  Created by AI on 2025/10/17.
//

import SwiftUI

// 通知のモデル
struct AppNotification: Identifiable {
    let id: String
    let type: NotificationType
    let userId: String
    let userName: String
    let userProfileImageURL: String?
    let message: String
    let timestamp: Date
    let isRead: Bool
    let relatedPhotoId: String?

    enum NotificationType {
        case comment
        case like
        case follow
        case post
    }
}

struct NotificationListView: View {
    @Binding var isPresented: Bool
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView()
                } else if notifications.isEmpty {
                    // 通知がない場合
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)

                        Text("通知はありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 通知リスト
                    List {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0  // リセット
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // すべて既読にする
                        markAllAsRead()
                    }) {
                        Text("すべて既読")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(notifications.allSatisfy { $0.isRead })
                }
            }
            .onAppear {
                dragOffset = 0  // 初期化
                loadNotifications()
            }
        }
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 右方向のドラッグのみ許可（正の値のみ）
                    if value.translation.width > 0 {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    // 画面幅の30%以上ドラッグしたら閉じる
                    if value.translation.width > UIScreen.main.bounds.width * 0.3 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0  // リセット
                            isPresented = false
                        }
                    } else {
                        // 元の位置に戻る
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    private func loadNotifications() {
        isLoading = true

        // TODO: Firestoreから通知を取得
        // 仮のデータで動作確認
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            notifications = [
                AppNotification(
                    id: "1",
                    type: .comment,
                    userId: "user1",
                    userName: "田中太郎",
                    userProfileImageURL: nil,
                    message: "があなたの写真にコメントしました",
                    timestamp: Date().addingTimeInterval(-3600),
                    isRead: false,
                    relatedPhotoId: "photo1"
                ),
                AppNotification(
                    id: "2",
                    type: .like,
                    userId: "user2",
                    userName: "佐藤花子",
                    userProfileImageURL: nil,
                    message: "があなたの写真にいいねしました",
                    timestamp: Date().addingTimeInterval(-7200),
                    isRead: false,
                    relatedPhotoId: "photo2"
                ),
                AppNotification(
                    id: "3",
                    type: .follow,
                    userId: "user3",
                    userName: "鈴木一郎",
                    userProfileImageURL: nil,
                    message: "があなたをフォローしました",
                    timestamp: Date().addingTimeInterval(-86400),
                    isRead: true,
                    relatedPhotoId: nil
                )
            ]
            isLoading = false
        }
    }

    private func markAllAsRead() {
        // TODO: Firestoreで既読状態を更新
        notifications = notifications.map { notification in
            AppNotification(
                id: notification.id,
                type: notification.type,
                userId: notification.userId,
                userName: notification.userName,
                userProfileImageURL: notification.userProfileImageURL,
                message: notification.message,
                timestamp: notification.timestamp,
                isRead: true,
                relatedPhotoId: notification.relatedPhotoId
            )
        }
    }
}

// 通知の行表示
struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // プロフィール画像
            if let imageURL = notification.userProfileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 4) {
                // ユーザー名 + メッセージ
                HStack(spacing: 4) {
                    Text(notification.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // タイムスタンプ
                Text(timeAgoString(from: notification.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 未読インジケーター
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .cornerRadius(8)
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "たった今"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)時間前"
        } else {
            let days = Int(interval / 86400)
            return "\(days)日前"
        }
    }
}

#Preview {
    NotificationListView(isPresented: .constant(true))
}
