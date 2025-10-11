//
//  CachedAsyncImage.swift
//  GAGA
//
//  Created by AI on 2025/10/12.
//

import SwiftUI

/// NetworkManagerを使用したキャッシュ対応のAsyncImage
/// 既存のAsyncImageと同じインターフェースで使用可能
struct CachedAsyncImage<Content: View>: View {
    let url: String
    let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty
    @State private var loadTask: Task<Void, Never>?

    init(url: String, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .task {
                await loadImage()
            }
            .onDisappear {
                loadTask?.cancel()
            }
    }

    private func loadImage() async {
        loadTask = Task {
            do {
                let image = try await NetworkManager.shared.downloadImage(from: url)

                // キャンセルされていないかチェック
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    phase = .success(Image(uiImage: image))
                }
            } catch {
                // キャンセルされていないかチェック
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    phase = .failure(error)
                }
                print("❌ Failed to load image: \(error.localizedDescription)")
            }
        }

        await loadTask?.value
    }
}

// MARK: - AsyncImagePhase Extension

/// AsyncImagePhaseの代替として使用
extension AsyncImagePhase {
    var image: Image? {
        switch self {
        case .success(let image):
            return image
        default:
            return nil
        }
    }
}
