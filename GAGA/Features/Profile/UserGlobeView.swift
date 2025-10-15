//
//  UserGlobeView.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import SwiftUI

struct UserGlobeView: View {
    let userId: String
    var onPhotoDeleted: (() -> Void)? = nil
    @StateObject private var appState = AppStateManager.shared
    @State private var selectedCountry: Country?
    @State private var selectedPhoto: Photo?
    @State private var showPhotoDetail = false

    var body: some View {
        ZStack {
            GlobeView(
                selectedCountry: $selectedCountry,
                selectedPhoto: $selectedPhoto,
                showPhotoDetail: $showPhotoDetail,
                photos: appState.userPhotos
            )

            // ローディングインジケーター（初回ロード時のみ表示）
            if appState.isLoadingPhotos && appState.userPhotos.isEmpty {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("地球儀を読み込み中...")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } else if appState.userPhotos.isEmpty && !appState.isLoadingPhotos {
                VStack {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.black.opacity(0.3))
                    Text("写真を投稿して\n地球を埋めよう")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black.opacity(0.5))
                        .padding()
                }
            }

            // Invisible NavigationLink for photo detail
            NavigationLink(
                destination: selectedPhoto.map { photo in
                    PhotoDetailView(photo: photo, onDelete: {
                        // 削除時の処理：写真リストを再読み込み
                        Task {
                            await AppStateManager.shared.refreshUserPhotos(userId: userId)
                        }
                        // ProfileViewに削除を通知
                        onPhotoDeleted?()
                    })
                },
                isActive: $showPhotoDetail
            ) {
                EmptyView()
            }
            .hidden()
        }
        .onAppear {
            // キャッシュがあれば即座に表示、なければロード
            Task {
                await appState.loadUserPhotos(userId: userId, forceRefresh: false)
            }
        }
    }
}

#Preview {
    UserGlobeView(userId: "test-user-id")
}
