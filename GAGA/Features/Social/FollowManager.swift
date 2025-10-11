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
    func follow(followerId: String, followingId: String) async throws {
        try await FirebaseService.shared.followUser(
            followerId: followerId,
            followingId: followingId
        )
        isFollowing[followingId] = true
        print("✅ FollowManager: Followed \(followingId)")
    }

    // フォロー解除
    func unfollow(followerId: String, followingId: String) async throws {
        try await FirebaseService.shared.unfollowUser(
            followerId: followerId,
            followingId: followingId
        )
        isFollowing[followingId] = false
        print("✅ FollowManager: Unfollowed \(followingId)")
    }

    // フォロワーリストを取得
    func loadFollowers(for userId: String) async throws {
        followers = try await FirebaseService.shared.getFollowers(userId: userId)
        print("✅ FollowManager: Loaded \(followers.count) followers")
    }

    // フォロー中リストを取得
    func loadFollowing(for userId: String) async throws {
        following = try await FirebaseService.shared.getFollowing(userId: userId)
        print("✅ FollowManager: Loaded \(following.count) following")
    }

    // フォロー状態を確認
    func checkFollowStatus(followerId: String, followingId: String) async -> Bool {
        if let cached = isFollowing[followingId] {
            return cached
        }

        do {
            let status = try await FirebaseService.shared.isFollowing(
                followerId: followerId,
                followingId: followingId
            )
            isFollowing[followingId] = status
            return status
        } catch {
            print("❌ FollowManager: Failed to check follow status: \(error)")
            return false
        }
    }
}
