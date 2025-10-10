//
//  FollowManager.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation

@MainActor
class FollowManager: ObservableObject {
    @Published var followers: [User] = []
    @Published var following: [User] = []
    @Published var isFollowing: [String: Bool] = [:]

    // ユーザーをフォロー
    func follow(userId: String) async throws {
        // TODO: Firestoreにフォロー関係を保存
        // await FirebaseService.shared.followUser(userId)

        isFollowing[userId] = true
    }

    // フォロー解除
    func unfollow(userId: String) async throws {
        // TODO: Firestoreからフォロー関係を削除
        // await FirebaseService.shared.unfollowUser(userId)

        isFollowing[userId] = false
    }

    // フォロワーリストを取得
    func loadFollowers(for userId: String) async throws {
        // TODO: Firestoreからフォロワーリストを取得
        followers = []
    }

    // フォロー中リストを取得
    func loadFollowing(for userId: String) async throws {
        // TODO: Firestoreからフォロー中リストを取得
        following = []
    }

    // フォロー状態を確認
    func checkFollowStatus(userId: String) async -> Bool {
        // TODO: Firestoreでフォロー状態を確認
        return isFollowing[userId] ?? false
    }
}
