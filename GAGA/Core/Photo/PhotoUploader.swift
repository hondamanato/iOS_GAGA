//
//  PhotoUploader.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import UIKit

class PhotoUploader {
    static let shared = PhotoUploader()

    private let storageService = StorageService.shared

    private init() {}

    // Firebase Storageに写真をアップロード
    func uploadPhoto(_ imageData: Data, userId: String, countryCode: String, photoId: String, size: String) async throws -> String {
        let path = "photos/\(userId)/\(countryCode)/\(size)/\(photoId).jpg"
        return try await storageService.uploadFile(imageData, path: path)
    }

    // 3サイズの写真をアップロード
    func uploadPhotoSet(original: Data, medium: Data, thumbnail: Data, userId: String, countryCode: String) async throws -> (photoId: String, original: String, medium: String, thumbnail: String) {
        let photoId = UUID().uuidString

        print("📸 Uploading photo set for country: \(countryCode)")

        // 並列アップロード
        async let originalURL = uploadPhoto(original, userId: userId, countryCode: countryCode, photoId: photoId, size: "original")
        async let mediumURL = uploadPhoto(medium, userId: userId, countryCode: countryCode, photoId: photoId, size: "medium")
        async let thumbnailURL = uploadPhoto(thumbnail, userId: userId, countryCode: countryCode, photoId: photoId, size: "thumbnail")

        let urls = try await (originalURL, mediumURL, thumbnailURL)
        print("✅ All 3 sizes uploaded successfully")

        return (photoId, urls.0, urls.1, urls.2)
    }

    // 写真削除
    func deletePhoto(userId: String, countryCode: String, photoId: String) async throws {
        let sizes = ["original", "medium", "thumbnail"]

        for size in sizes {
            let path = "photos/\(userId)/\(countryCode)/\(size)/\(photoId).jpg"
            try await storageService.deleteFile(path: path)
        }

        print("🗑️ Photo set deleted: \(photoId)")
    }
}
