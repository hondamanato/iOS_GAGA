//
//  UserGlobeView.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import SwiftUI

struct UserGlobeView: View {
    let userId: String
    @State private var photos: [String: Photo] = [:]
    @State private var selectedCountry: Country?
    @State private var selectedPhoto: Photo?
    @State private var showPhotoDetail = false

    var body: some View {
        ZStack {
            GlobeView(
                selectedCountry: $selectedCountry,
                selectedPhoto: $selectedPhoto,
                showPhotoDetail: $showPhotoDetail,
                photos: photos
            )

            if photos.isEmpty {
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
                            await loadUserPhotos()
                        }
                    })
                },
                isActive: $showPhotoDetail
            ) {
                EmptyView()
            }
            .hidden()
        }
        .task {
            await loadUserPhotos()
        }
    }

    private func loadUserPhotos() async {
        do {
            let userPhotos = try await FirebaseService.shared.getPhotos(for: userId)
            print("📸 Loaded \(userPhotos.count) photos for user profile")

            // 国コードをキーとしたディクショナリに変換（各国最新の1枚のみ）
            var photosDict: [String: Photo] = [:]
            for photo in userPhotos {
                // 既存の写真がない、または新しい写真の場合のみ更新
                if photosDict[photo.countryCode] == nil ||
                   photo.createdAt > photosDict[photo.countryCode]!.createdAt {
                    photosDict[photo.countryCode] = photo
                }
            }

            // メインスレッドで更新
            await MainActor.run {
                self.photos = photosDict
                print("✅ Updated profile globe with \(photosDict.count) countries")
            }
        } catch {
            print("❌ Failed to load photos: \(error)")
        }
    }
}

#Preview {
    UserGlobeView(userId: "test-user-id")
}
