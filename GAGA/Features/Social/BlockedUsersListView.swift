//
//  BlockedUsersListView.swift
//  GAGA
//
//  Created by AI on 2025/10/11.
//

import SwiftUI

struct BlockedUsersListView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var blockedUsers: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var userToUnblock: User?
    @State private var showUnblockConfirmation = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.black)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                    Button("再試行") {
                        Task {
                            await loadBlockedUsers()
                        }
                    }
                }
            } else if blockedUsers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.black)
                    Text("ブロック中のユーザーはいません")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        HStack(spacing: 16) {
                            // プロフィール画像
                            if let imageURL = user.profileImageURL {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                    default:
                                        Circle()
                                            .fill(Color.blue.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )
                            }

                            // ユーザー情報
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // ブロック解除ボタン
                            Button("解除") {
                                userToUnblock = user
                                showUnblockConfirmation = true
                            }
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("ブロック中")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBlockedUsers()
        }
        .refreshable {
            await loadBlockedUsers()
        }
        .alert("ブロック解除", isPresented: $showUnblockConfirmation) {
            Button("キャンセル", role: .cancel) {
                userToUnblock = nil
            }
            Button("解除", role: .destructive) {
                if let user = userToUnblock {
                    Task {
                        await unblockUser(user)
                    }
                }
            }
        } message: {
            if let user = userToUnblock {
                Text("\(user.displayName)のブロックを解除しますか？")
            }
        }
    }

    private func loadBlockedUsers() async {
        guard let currentUserId = authManager.currentUser?.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            blockedUsers = try await FirebaseService.shared.getBlockedUsers(userId: currentUserId)
            print("✅ Loaded \(blockedUsers.count) blocked users")
        } catch {
            print("❌ Failed to load blocked users: \(error)")
            errorMessage = "読み込みに失敗しました"
        }

        isLoading = false
    }

    private func unblockUser(_ user: User) async {
        guard let currentUserId = authManager.currentUser?.id else { return }

        do {
            try await FirebaseService.shared.unblockUser(blockerId: currentUserId, blockedId: user.id)

            // リストから削除
            await MainActor.run {
                blockedUsers.removeAll { $0.id == user.id }
                userToUnblock = nil
            }

            print("✅ Unblocked user: \(user.displayName)")
        } catch {
            print("❌ Failed to unblock user: \(error)")
            errorMessage = "ブロック解除に失敗しました"
        }
    }
}

#Preview {
    NavigationView {
        BlockedUsersListView()
    }
}
