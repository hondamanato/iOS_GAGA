//
//  SavedPhotosView.swift
//  GAGA
//
//  Created by AI on 2025/10/17.
//

import SwiftUI

struct SavedPhotosView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var savedPhotos: [Photo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedPhoto: Photo?
    @State private var showPhotoDetail = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else if savedPhotos.isEmpty {
                    // 空状態の表示
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))

                        Text("保存済みの投稿")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("保存した投稿はここに表示されます")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                    .padding()
                } else {
                    // グリッド表示
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(savedPhotos) { photo in
                            NavigationLink(destination: PhotoDetailView(photo: photo, onDelete: {
                                // 削除時にリストから削除
                                savedPhotos.removeAll { $0.id == photo.id }
                            })) {
                                GeometryReader { geometry in
                                    CachedAsyncImage(url: photo.thumbnailURL ?? photo.imageURL) { phase in
                                        switch phase {
                                        case .empty:
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .overlay(
                                                    ProgressView()
                                                )
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: geometry.size.width, height: geometry.size.width)
                                                .clipped()
                                        case .failure:
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                )
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .navigationTitle("保存済み")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadSavedPhotos()
            }
            .refreshable {
                await loadSavedPhotos()
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func loadSavedPhotos() async {
        guard let userId = authManager.currentUser?.id else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "ユーザー情報を取得できませんでした"
                self.showError = true
            }
            return
        }

        isLoading = true

        do {
            let photos = try await FirebaseService.shared.getSavedPhotos(for: userId)

            await MainActor.run {
                self.savedPhotos = photos
                self.isLoading = false
                self.errorMessage = nil
            }

            print("✅ Loaded \(photos.count) saved photos")
        } catch {
            print("❌ Failed to load saved photos: \(error)")

            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "保存済み投稿の読み込みに失敗しました"
                self.showError = true
            }
        }
    }
}

#Preview {
    SavedPhotosView()
}