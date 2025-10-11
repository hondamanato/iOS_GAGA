//
//  FollowListView.swift
//  GAGA
//
//  Created by AI on 2025/10/11.
//

import SwiftUI

enum FollowListType {
    case followers
    case following
}

struct FollowListView: View {
    let userId: String
    let listType: FollowListType

    @State private var users: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

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
                            await loadUsers()
                        }
                    }
                }
            } else if users.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: listType == .followers ? "person.2.slash" : "person.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.black)
                    Text(listType == .followers ? "フォロワーがいません" : "フォロー中のユーザーがいません")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(users) { user in
                    NavigationLink(destination: UserDetailView(user: user)) {
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
                                Text("\(user.visitedCountries.count)カ国訪問")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(listType == .followers ? "フォロワー" : "フォロー中")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUsers()
        }
        .refreshable {
            await loadUsers()
        }
    }

    private func loadUsers() async {
        isLoading = true
        errorMessage = nil

        do {
            users = try await {
                switch listType {
                case .followers:
                    return try await FirebaseService.shared.getFollowers(userId: userId)
                case .following:
                    return try await FirebaseService.shared.getFollowing(userId: userId)
                }
            }()

            print("✅ Loaded \(users.count) users for \(listType)")
        } catch {
            print("❌ Failed to load users: \(error)")
            errorMessage = "読み込みに失敗しました"
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        FollowListView(userId: "test-user-id", listType: .followers)
    }
}
