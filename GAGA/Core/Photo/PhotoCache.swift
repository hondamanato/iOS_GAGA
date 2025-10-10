//
//  PhotoCache.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import UIKit

class PhotoCache {
    static let shared = PhotoCache()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private var cacheDirectory: URL

    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("PhotoCache")

        // キャッシュディレクトリ作成
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // メモリキャッシュ設定
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }

    // メモリキャッシュに保存
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    // メモリキャッシュから取得
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    // ディスクキャッシュに保存
    func saveImageToDisk(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? data.write(to: fileURL)
    }

    // ディスクキャッシュから取得
    func loadImageFromDisk(forKey key: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    // キャッシュクリア
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
