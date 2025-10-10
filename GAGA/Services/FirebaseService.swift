//
//  FirebaseService.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User Operations

    // ユーザー情報を取得
    func getUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()

        guard document.exists else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        return try document.data(as: User.self)
    }

    // ユーザー情報を保存
    func saveUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
        print("✅ User saved: \(user.id)")
    }

    // ユーザー検索
    func searchUsers(query: String) async throws -> [User] {
        // TODO: Firestoreでユーザー検索
        // let snapshot = try await db.collection("users")
        //     .whereField("displayName", isGreaterThanOrEqualTo: query)
        //     .whereField("displayName", isLessThan: query + "\u{f8ff}")
        //     .getDocuments()

        return []
    }

    // MARK: - Photo Operations

    // 写真情報を保存
    func savePhoto(_ photo: Photo) async throws {
        try db.collection("photos").document(photo.id).setData(from: photo)
        print("✅ Photo saved: \(photo.id) for country \(photo.countryCode)")
    }

    // ユーザーの写真を取得
    func getPhotos(for userId: String) async throws -> [Photo] {
        let snapshot = try await db.collection("photos")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: Photo.self)
        }
    }

    // 国の写真を取得
    func getPhotosForCountry(countryCode: String) async throws -> [Photo] {
        let snapshot = try await db.collection("photos")
            .whereField("countryCode", isEqualTo: countryCode)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: Photo.self)
        }
    }

    // 写真を削除
    func deletePhoto(photoId: String) async throws {
        try await db.collection("photos").document(photoId).delete()
        print("🗑️ Photo deleted: \(photoId)")
    }

    // MARK: - Follow Operations

    // フォロー
    func followUser(followerId: String, followingId: String) async throws {
        // TODO: Firestoreにフォロー関係を保存
        // let followRef = db.collection("follows").document()
        // try await followRef.setData([
        //     "followerId": followerId,
        //     "followingId": followingId,
        //     "createdAt": FieldValue.serverTimestamp()
        // ])
    }

    // フォロー解除
    func unfollowUser(followerId: String, followingId: String) async throws {
        // TODO: Firestoreからフォロー関係を削除
    }

    // フォロワー一覧を取得
    func getFollowers(userId: String) async throws -> [User] {
        // TODO: Firestoreからフォロワー一覧を取得
        return []
    }

    // フォロー中一覧を取得
    func getFollowing(userId: String) async throws -> [User] {
        // TODO: Firestoreからフォロー中一覧を取得
        return []
    }
}
