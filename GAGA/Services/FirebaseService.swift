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

    // MARK: - Username Operations

    // ユーザーネームの利用可能性をチェック
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let normalizedUsername = username.lowercased()
        let document = try await db.collection("usernames").document(normalizedUsername).getDocument()
        return !document.exists
    }

    // ユーザーネームを予約（新規登録時）
    func reserveUsername(_ username: String, userId: String) async throws {
        let normalizedUsername = username.lowercased()

        // 重複チェック
        let isAvailable = try await checkUsernameAvailability(normalizedUsername)
        guard isAvailable else {
            throw NSError(domain: "FirebaseService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Username already taken"])
        }

        // usernamesコレクションに保存
        try await db.collection("usernames").document(normalizedUsername).setData([
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ])

        print("✅ Username reserved: \(normalizedUsername) for user \(userId)")
    }

    // ユーザーネームを更新
    func updateUsername(oldUsername: String, newUsername: String, userId: String) async throws {
        let normalizedOldUsername = oldUsername.lowercased()
        let normalizedNewUsername = newUsername.lowercased()

        // 同じユーザーネームの場合は何もしない
        guard normalizedOldUsername != normalizedNewUsername else { return }

        // 新しいユーザーネームの重複チェック
        let isAvailable = try await checkUsernameAvailability(normalizedNewUsername)
        guard isAvailable else {
            throw NSError(domain: "FirebaseService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Username already taken"])
        }

        // 古いユーザーネームを削除
        try await db.collection("usernames").document(normalizedOldUsername).delete()

        // 新しいユーザーネームを予約
        try await db.collection("usernames").document(normalizedNewUsername).setData([
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ])

        print("✅ Username updated: \(normalizedOldUsername) -> \(normalizedNewUsername)")
    }

    // ユーザー検索（表示名とユーザーネームで部分一致）
    func searchUsers(query: String) async throws -> [User] {
        guard !query.isEmpty else { return [] }

        print("🔍 Searching users with query: \(query)")

        var allUsers: [User] = []
        var userIds = Set<String>()

        // displayNameで検索
        let displayNameSnapshot = try await db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()

        for doc in displayNameSnapshot.documents {
            if let user = try? doc.data(as: User.self), !userIds.contains(user.id) {
                allUsers.append(user)
                userIds.insert(user.id)
            }
        }

        // usernameで検索（@がある場合は削除）
        let cleanQuery = query.hasPrefix("@") ? String(query.dropFirst()) : query
        let usernameSnapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: cleanQuery.lowercased())
            .whereField("username", isLessThan: cleanQuery.lowercased() + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()

        for doc in usernameSnapshot.documents {
            if let user = try? doc.data(as: User.self), !userIds.contains(user.id) {
                allUsers.append(user)
                userIds.insert(user.id)
            }
        }

        print("✅ Found \(allUsers.count) users")
        return Array(allUsers.prefix(20))
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
        // フォロー関係をFirestoreに保存
        let followRef = db.collection("follows").document()
        try await followRef.setData([
            "followerId": followerId,
            "followingId": followingId,
            "createdAt": FieldValue.serverTimestamp()
        ])

        // フォロワー数とフォロー中数を更新
        let followerRef = db.collection("users").document(followerId)
        let followingRef = db.collection("users").document(followingId)

        try await followerRef.updateData(["followingCount": FieldValue.increment(Int64(1))])
        try await followingRef.updateData(["followerCount": FieldValue.increment(Int64(1))])

        print("✅ User \(followerId) followed \(followingId)")
    }

    // フォロー解除
    func unfollowUser(followerId: String, followingId: String) async throws {
        // フォロー関係を検索して削除
        let snapshot = try await db.collection("follows")
            .whereField("followerId", isEqualTo: followerId)
            .whereField("followingId", isEqualTo: followingId)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.delete()
        }

        // フォロワー数とフォロー中数を更新
        let followerRef = db.collection("users").document(followerId)
        let followingRef = db.collection("users").document(followingId)

        try await followerRef.updateData(["followingCount": FieldValue.increment(Int64(-1))])
        try await followingRef.updateData(["followerCount": FieldValue.increment(Int64(-1))])

        print("✅ User \(followerId) unfollowed \(followingId)")
    }

    // フォロワー一覧を取得
    func getFollowers(userId: String) async throws -> [User] {
        // このユーザーをフォローしている人を取得
        let snapshot = try await db.collection("follows")
            .whereField("followingId", isEqualTo: userId)
            .getDocuments()

        let followerIds = snapshot.documents.map { $0.data()["followerId"] as? String }.compactMap { $0 }

        // ユーザー情報を取得
        var followers: [User] = []
        for id in followerIds {
            if let user = try? await getUser(userId: id) {
                followers.append(user)
            }
        }

        return followers
    }

    // フォロー中一覧を取得
    func getFollowing(userId: String) async throws -> [User] {
        // このユーザーがフォローしている人を取得
        let snapshot = try await db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
            .getDocuments()

        let followingIds = snapshot.documents.map { $0.data()["followingId"] as? String }.compactMap { $0 }

        // ユーザー情報を取得
        var following: [User] = []
        for id in followingIds {
            if let user = try? await getUser(userId: id) {
                following.append(user)
            }
        }

        return following
    }

    // フォロー状態を確認
    func isFollowing(followerId: String, followingId: String) async throws -> Bool {
        let snapshot = try await db.collection("follows")
            .whereField("followerId", isEqualTo: followerId)
            .whereField("followingId", isEqualTo: followingId)
            .limit(to: 1)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }

    // MARK: - User Data Updates

    // ユーザーの訪問国リストに国を追加
    func addVisitedCountry(userId: String, countryCode: String) async throws {
        let userRef = db.collection("users").document(userId)

        // 既存の訪問国リストを取得
        let document = try await userRef.getDocument()
        guard var user = try? document.data(as: User.self) else {
            print("❌ User not found: \(userId)")
            return
        }

        // 重複チェック
        if !user.visitedCountries.contains(countryCode) {
            user.visitedCountries.append(countryCode)
            user.updatedAt = Date()

            // Firestoreを更新
            try userRef.setData(from: user)
            print("✅ Added \(countryCode) to visited countries for user \(userId)")
        } else {
            print("ℹ️ Country \(countryCode) already in visited list")
        }
    }

    // MARK: - Block Operations

    // ユーザーをブロック
    func blockUser(blockerId: String, blockedId: String) async throws {
        let blockerRef = db.collection("users").document(blockerId)

        // ブロッカーのユーザー情報を取得
        let document = try await blockerRef.getDocument()
        guard var blocker = try? document.data(as: User.self) else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        // 既にブロックされているかチェック
        guard !blocker.blockedUserIds.contains(blockedId) else {
            print("ℹ️ User \(blockedId) is already blocked")
            return
        }

        // ブロックリストに追加
        blocker.blockedUserIds.append(blockedId)
        blocker.updatedAt = Date()

        // Firestoreを更新
        try blockerRef.setData(from: blocker)

        // お互いのフォロー関係を解除
        try? await unfollowUser(followerId: blockerId, followingId: blockedId)
        try? await unfollowUser(followerId: blockedId, followingId: blockerId)

        print("✅ User \(blockerId) blocked \(blockedId)")
    }

    // ブロックを解除
    func unblockUser(blockerId: String, blockedId: String) async throws {
        let blockerRef = db.collection("users").document(blockerId)

        // ブロッカーのユーザー情報を取得
        let document = try await blockerRef.getDocument()
        guard var blocker = try? document.data(as: User.self) else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        // ブロックリストから削除
        blocker.blockedUserIds.removeAll { $0 == blockedId }
        blocker.updatedAt = Date()

        // Firestoreを更新
        try blockerRef.setData(from: blocker)

        print("✅ User \(blockerId) unblocked \(blockedId)")
    }

    // ブロックされているユーザーリストを取得
    func getBlockedUsers(userId: String) async throws -> [User] {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let user = try? document.data(as: User.self) else {
            return []
        }

        var blockedUsers: [User] = []
        for blockedId in user.blockedUserIds {
            if let blockedUser = try? await getUser(userId: blockedId) {
                blockedUsers.append(blockedUser)
            }
        }

        return blockedUsers
    }

    // ブロック状態を確認
    func isBlocked(blockerId: String, blockedId: String) async throws -> Bool {
        let document = try await db.collection("users").document(blockerId).getDocument()
        guard let blocker = try? document.data(as: User.self) else {
            return false
        }

        return blocker.blockedUserIds.contains(blockedId)
    }

    // MARK: - Comment Operations

    // 写真のコメント一覧を取得
    func getComments(for photoId: String) async throws -> [Comment] {
        do {
            let snapshot = try await db.collection("photos")
                .document(photoId)
                .collection("comments")
                .order(by: "createdAt", descending: true)  // 新しい順に変更
                .getDocuments()

            return try snapshot.documents.compactMap { doc in
                do {
                    var comment = try doc.data(as: Comment.self)
                    // FirestoreのドキュメントIDを使用
                    comment.id = doc.documentID

                    // createdAt が nil の場合、現在時刻を使用
                    if comment.createdAt == nil {
                        comment = Comment(
                            id: comment.id,
                            photoId: comment.photoId,
                            userId: comment.userId,
                            username: comment.username,
                            text: comment.text,
                            createdAt: Date()
                        )
                    }

                    return comment
                } catch {
                    print("⚠️ Failed to decode comment document \(doc.documentID): \(error)")
                    // デコード失敗時は nil を返してスキップ
                    return nil
                }
            }
        } catch {
            print("❌ Failed to fetch comments from Firestore: \(error)")
            throw error
        }
    }

    // コメントを投稿
    func postComment(photoId: String, userId: String, username: String, text: String) async throws -> Comment {
        let photoRef = db.collection("photos").document(photoId)
        let commentRef = photoRef.collection("comments").document()

        // コメントデータを作成
        let comment = Comment(
            id: commentRef.documentID,
            photoId: photoId,
            userId: userId,
            username: username,
            text: text,
            createdAt: Date()
        )

        // トランザクションでコメント追加とカウント更新を同時実行
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let photoDocument: DocumentSnapshot
            do {
                try photoDocument = transaction.getDocument(photoRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let currentCommentCount = photoDocument.data()?["commentCount"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve comment count"
                ])
                errorPointer?.pointee = error
                return nil
            }

            // コメント数を増やす
            transaction.updateData(["commentCount": currentCommentCount + 1], forDocument: photoRef)

            // コメントを追加（IDフィールドも含めて保存）
            transaction.setData([
                "id": comment.id,  // IDフィールドを追加
                "photoId": comment.photoId,
                "userId": comment.userId,
                "username": comment.username,
                "text": comment.text,
                "createdAt": Timestamp(date: comment.createdAt ?? Date())
            ], forDocument: commentRef)

            return nil
        })

        print("✅ Comment posted: \(commentRef.documentID)")
        return comment
    }

    // コメントを削除（オーナーまたは写真の投稿者のみ）
    func deleteComment(commentId: String, photoId: String) async throws {
        let photoRef = db.collection("photos").document(photoId)
        let commentRef = photoRef.collection("comments").document(commentId)

        // トランザクションでコメント削除とカウント更新を同時実行
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let photoDocument: DocumentSnapshot
            do {
                try photoDocument = transaction.getDocument(photoRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let currentCommentCount = photoDocument.data()?["commentCount"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve comment count"
                ])
                errorPointer?.pointee = error
                return nil
            }

            // コメント数を減らす（0未満にはしない）
            transaction.updateData(["commentCount": max(0, currentCommentCount - 1)], forDocument: photoRef)

            // コメントを削除
            transaction.deleteDocument(commentRef)

            return nil
        })

        print("🗑️ Comment deleted: \(commentId)")
    }

    // MARK: - Saved Photos

    // 保存済み（ブックマーク済み）写真を取得
    func getSavedPhotos(for userId: String) async throws -> [Photo] {
        do {
            // ユーザーのブックマークコレクションから保存済み写真IDを取得
            let bookmarksSnapshot = try await db.collection("users")
                .document(userId)
                .collection("bookmarks")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            let photoIds = bookmarksSnapshot.documents.map { $0.documentID }

            guard !photoIds.isEmpty else {
                print("📚 No saved photos found for user \(userId)")
                return []
            }

            // 各写真の詳細情報を取得
            var savedPhotos: [Photo] = []

            for photoId in photoIds {
                do {
                    let photoDoc = try await db.collection("photos")
                        .document(photoId)
                        .getDocument()

                    if photoDoc.exists {
                        if let data = photoDoc.data() {
                            // Photoインスタンスを手動で作成（IDを設定するため）
                            var photo = Photo(
                                id: photoDoc.documentID,
                                userId: data["userId"] as? String ?? "",
                                countryCode: data["countryCode"] as? String ?? "",
                                imageURL: data["imageURL"] as? String ?? "",
                                thumbnailURL: data["thumbnailURL"] as? String ?? "",
                                originalURL: data["originalURL"] as? String,
                                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                            )
                            // その他のプロパティを設定
                            photo.likeCount = data["likeCount"] as? Int ?? 0
                            photo.commentCount = data["commentCount"] as? Int ?? 0
                            photo.caption = data["caption"] as? String

                            savedPhotos.append(photo)
                        }
                    }
                } catch {
                    print("⚠️ Failed to fetch photo \(photoId): \(error)")
                    // 個別の写真取得に失敗しても続行
                    continue
                }
            }

            print("📚 Found \(savedPhotos.count) saved photos for user \(userId)")
            return savedPhotos
        } catch {
            print("❌ Error fetching saved photos: \(error)")
            throw error
        }
    }
}
