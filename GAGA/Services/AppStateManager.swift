//
//  AppStateManager.swift
//  GAGA
//
//  Created by AI on 2025/10/15.
//

import SwiftUI
import Combine

/// アプリ全体の状態を管理するシングルトン
/// - 写真データのキャッシュ管理
/// - バックグラウンドでのプリロード
/// - タブ切り替え時の最適化
@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    // MARK: - Published Properties

    /// 現在のユーザーの写真データ（国コードをキーとしたディクショナリ）
    @Published var userPhotos: [String: Photo] = [:]

    /// 写真データがロード中かどうか
    @Published var isLoadingPhotos: Bool = false

    /// 最後にロードした時刻
    @Published var lastLoadTime: Date?

    // MARK: - Private Properties

    private var currentUserId: String?
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    private init() {
        print("🌍 AppStateManager initialized")
    }

    // MARK: - Public Methods

    /// ユーザーの写真データをロード（キャッシュ優先）
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - forceRefresh: キャッシュを無視して強制的に再取得
    func loadUserPhotos(userId: String, forceRefresh: Bool = false) async {
        // 既に同じユーザーのデータがあり、強制リフレッシュでない場合はスキップ
        if !forceRefresh,
           currentUserId == userId,
           !userPhotos.isEmpty,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < 60 { // 60秒以内ならキャッシュを使用
            print("✅ Using cached photos for user \(userId) (\(userPhotos.count) countries)")
            return
        }

        // 既に実行中のタスクがあればキャンセル
        loadTask?.cancel()

        // 新しいタスクを開始
        loadTask = Task {
            await performLoad(userId: userId)
        }

        await loadTask?.value
    }

    /// バックグラウンドで写真データをプリロード（非同期・待機しない）
    /// - Parameter userId: ユーザーID
    func preloadUserPhotos(userId: String) {
        Task {
            await loadUserPhotos(userId: userId, forceRefresh: false)
        }
    }

    /// 写真データを強制的にリフレッシュ
    /// - Parameter userId: ユーザーID
    func refreshUserPhotos(userId: String) async {
        await loadUserPhotos(userId: userId, forceRefresh: true)
    }

    /// キャッシュをクリア
    func clearCache() {
        userPhotos.removeAll()
        currentUserId = nil
        lastLoadTime = nil
        print("🗑️ Cache cleared")
    }

    // MARK: - Private Methods

    private func performLoad(userId: String) async {
        isLoadingPhotos = true

        do {
            let photos = try await FirebaseService.shared.getPhotos(for: userId)

            // Task がキャンセルされていないかチェック
            guard !Task.isCancelled else {
                print("⚠️ Load task cancelled for user \(userId)")
                return
            }

            print("📸 Loaded \(photos.count) photos for user \(userId)")

            // 国コードをキーとしたディクショナリに変換（各国最新の1枚のみ）
            var photosDict: [String: Photo] = [:]
            for photo in photos {
                // 既存の写真がない、または新しい写真の場合のみ更新
                if photosDict[photo.countryCode] == nil ||
                   photo.createdAt > photosDict[photo.countryCode]!.createdAt {
                    photosDict[photo.countryCode] = photo
                }
            }

            // メインスレッドで更新
            await MainActor.run {
                self.userPhotos = photosDict
                self.currentUserId = userId
                self.lastLoadTime = Date()
                self.isLoadingPhotos = false
                print("✅ Updated AppStateManager with \(photosDict.count) countries")
            }
        } catch {
            print("❌ Failed to load photos: \(error)")
            await MainActor.run {
                self.isLoadingPhotos = false
            }
        }
    }
}
