//
//  PhotoInteractionService.swift
//  GAGA
//
//  Created by AI on 2025/10/12.
//

import Foundation
import FirebaseFirestore

class PhotoInteractionService {
    static let shared = PhotoInteractionService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Like Functions

    /// 写真にいいねをつける
    func likePhoto(photoId: String, userId: String) async throws {
        let photoRef = db.collection("photos").document(photoId)
        let likeRef = db.collection("photos").document(photoId).collection("likes").document(userId)

        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let photoDocument: DocumentSnapshot
            do {
                try photoDocument = transaction.getDocument(photoRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let oldLikeCount = photoDocument.data()?["likeCount"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve like count from snapshot \(photoDocument)"
                ])
                errorPointer?.pointee = error
                return nil
            }

            // いいね数を増やす
            transaction.updateData(["likeCount": oldLikeCount + 1], forDocument: photoRef)

            // likesサブコレクションに追加
            transaction.setData([
                "userId": userId,
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: likeRef)

            return nil
        })

        print("✅ Liked photo: \(photoId)")
    }

    /// 写真のいいねを解除
    func unlikePhoto(photoId: String, userId: String) async throws {
        let photoRef = db.collection("photos").document(photoId)
        let likeRef = db.collection("photos").document(photoId).collection("likes").document(userId)

        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let photoDocument: DocumentSnapshot
            do {
                try photoDocument = transaction.getDocument(photoRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let oldLikeCount = photoDocument.data()?["likeCount"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve like count from snapshot \(photoDocument)"
                ])
                errorPointer?.pointee = error
                return nil
            }

            // いいね数を減らす（0未満にはしない）
            transaction.updateData(["likeCount": max(0, oldLikeCount - 1)], forDocument: photoRef)

            // likesサブコレクションから削除
            transaction.deleteDocument(likeRef)

            return nil
        })

        print("✅ Unliked photo: \(photoId)")
    }

    /// ユーザーが写真にいいねしているかチェック
    func checkIfLiked(photoId: String, userId: String) async throws -> Bool {
        let likeRef = db.collection("photos").document(photoId).collection("likes").document(userId)
        let snapshot = try await likeRef.getDocument()
        return snapshot.exists
    }

    // MARK: - Bookmark Functions

    /// 写真を保存
    func bookmarkPhoto(photoId: String, userId: String) async throws {
        let bookmarkRef = db.collection("users").document(userId).collection("bookmarks").document(photoId)

        try await bookmarkRef.setData([
            "photoId": photoId,
            "createdAt": FieldValue.serverTimestamp()
        ])

        print("✅ Bookmarked photo: \(photoId)")
    }

    /// 写真の保存を解除
    func unbookmarkPhoto(photoId: String, userId: String) async throws {
        let bookmarkRef = db.collection("users").document(userId).collection("bookmarks").document(photoId)

        try await bookmarkRef.delete()

        print("✅ Unbookmarked photo: \(photoId)")
    }

    /// ユーザーが写真を保存しているかチェック
    func checkIfBookmarked(photoId: String, userId: String) async throws -> Bool {
        let bookmarkRef = db.collection("users").document(userId).collection("bookmarks").document(photoId)
        let snapshot = try await bookmarkRef.getDocument()
        return snapshot.exists
    }

    /// ユーザーが保存した写真一覧を取得
    func getBookmarkedPhotos(userId: String) async throws -> [String] {
        let snapshot = try await db.collection("users").document(userId).collection("bookmarks")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { $0.data()["photoId"] as? String }
    }
}
