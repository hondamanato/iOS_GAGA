//
//  StorageService.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import FirebaseStorage

class StorageService {
    static let shared = StorageService()

    private let storage = Storage.storage()

    private init() {}

    // Firebase Storageにファイルをアップロード
    func uploadFile(_ data: Data, path: String) async throws -> String {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        print("📤 Uploading to path: \(path), size: \(data.count) bytes")

        let _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()

        print("✅ Upload successful: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }

    // Firebase Storageからファイルを削除
    func deleteFile(path: String) async throws {
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
        print("🗑️ File deleted: \(path)")
    }

    // URLから画像をダウンロード
    func downloadImage(url: String) async throws -> Data {
        guard let imageURL = URL(string: url) else {
            throw NSError(domain: "StorageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: imageURL)
        return data
    }
}
