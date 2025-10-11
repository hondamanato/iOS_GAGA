//
//  NetworkManager.swift
//  GAGA
//
//  Created by AI on 2025/10/12.
//

import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()

    let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default

        // メモリキャッシュ: 50MB
        // ディスクキャッシュ: 200MB
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            directory: nil
        )
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad

        self.session = URLSession(configuration: config)
    }

    // 画像をダウンロード（キャッシュ優先）
    func downloadImage(from urlString: String) async throws -> UIImage {
        // まずPhotoCacheのメモリキャッシュをチェック
        if let cachedImage = PhotoCache.shared.getImage(forKey: urlString) {
            print("✅ Cache hit (memory): \(urlString.lastPathComponent)")
            return cachedImage
        }

        // PhotoCacheのディスクキャッシュをチェック
        let cacheKey = urlString.safeCacheKey
        if let diskImage = PhotoCache.shared.loadImageFromDisk(forKey: cacheKey) {
            print("✅ Cache hit (disk): \(urlString.lastPathComponent)")
            PhotoCache.shared.setImage(diskImage, forKey: urlString)
            return diskImage
        }

        // ネットワークからダウンロード
        guard let imageURL = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        print("📥 Downloading: \(urlString.lastPathComponent)")
        let (data, response) = try await session.data(from: imageURL)

        // レスポンスをチェック
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        guard let image = UIImage(data: data) else {
            throw NetworkError.invalidImageData
        }

        // キャッシュに保存
        PhotoCache.shared.setImage(image, forKey: urlString)
        PhotoCache.shared.saveImageToDisk(image, forKey: cacheKey)
        print("💾 Cached: \(urlString.lastPathComponent)")

        return image
    }
}

// MARK: - NetworkError

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidImageData

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .invalidImageData:
            return "画像データが無効です"
        }
    }
}

// MARK: - String Extension

extension String {
    // URLを安全なキャッシュキーに変換
    var safeCacheKey: String {
        return self
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
    }

    // URLから最後のパスコンポーネントを取得（ログ用）
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
}
