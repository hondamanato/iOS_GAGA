//
//  ContentView.swift
//  GAGA
//
//  Created by 本多真翔 on 2025/10/09.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedCountry: Country?
    @State private var selectedPhoto: Photo?
    @State private var showPhotoDetail = false
    @State private var showCameraView = false
    @State private var selectedImage: UIImage?
    @State private var photos: [String: Photo] = [:]

    var body: some View {
        NavigationView {
            ZStack {
                // 3D地球儀
                GlobeView(
                    selectedCountry: $selectedCountry,
                    selectedPhoto: $selectedPhoto,
                    showPhotoDetail: $showPhotoDetail,
                    photos: photos
                )
                .edgesIgnoringSafeArea(.all)

                // 上部オーバーレイ
                VStack {
                    HStack {
                        // 左上：アプリ名
                        Text("GAGA")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()

                        Spacer()

                        // 右上：通知アイコン
                        Button(action: {
                            // TODO: 通知画面を開く
                        }) {
                            Image(systemName: "bell")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }

                    Spacer()

                    // 国選択時の情報表示
                    if let country = selectedCountry {
                        VStack(spacing: 12) {
                            Text(country.nameJa ?? country.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)

                            Button(action: {
                                showCameraView = true
                            }) {
                                Label("写真を投稿", systemImage: "photo.badge.plus")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }

                // Invisible NavigationLink for photo detail
                NavigationLink(
                    destination: selectedPhoto.map { photo in
                        PhotoDetailView(photo: photo, onDelete: {
                            // 削除時の処理：写真リストを再読み込み
                            Task {
                                await loadPhotos()
                            }
                        })
                    },
                    isActive: $showPhotoDetail
                ) {
                    EmptyView()
                }
                .hidden()

                // Invisible NavigationLink for camera/composer view
                NavigationLink(
                    destination: selectedCountry.map { country in
                        PhotoComposerView(selectedImage: $selectedImage, selectedCountry: .constant(country))
                    },
                    isActive: $showCameraView
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationBarHidden(true)
            .toolbar(.visible, for: .tabBar) // タブバーを明示的に表示
            .onAppear {
                // 起動時に写真を読み込み
                Task {
                    await loadPhotos()
                }
                
                // プロフィール画面用のマイ地球儀をバックグラウンドでプリロード
                if let userId = AuthManager.shared.currentUser?.id {
                    AppStateManager.shared.preloadUserPhotos(userId: userId)
                    print("🔄 Preloading user photos for profile tab from globe view")
                }
            }
        }
    }

    // 写真を読み込む
    private func loadPhotos() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        do {
            let userPhotos = try await FirebaseService.shared.getPhotos(for: userId)
            print("📸 Loaded \(userPhotos.count) photos from Firestore")

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
                print("✅ Updated globe with \(photosDict.count) countries")
            }
        } catch {
            print("❌ Failed to load photos: \(error)")
        }
    }
}

// メインのタブビュー
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("地球儀", systemImage: "globe")
                }
                .tag(0)

            UserSearchView()
                .tabItem {
                    Label("探す", systemImage: "magnifyingglass")
                }
                .tag(1)

            SavedPhotosView()
                .tabItem {
                    Label("保存済み", systemImage: "bookmark.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("プロフィール", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.black)
        .onChange(of: selectedTab) { newTab in
            // タブが切り替わったときにプロフィールタブの写真をプリロード
            if newTab == 3, let userId = authManager.currentUser?.id {
                Task {
                    await AppStateManager.shared.loadUserPhotos(userId: userId, forceRefresh: false)
                    print("🔄 Preloaded photos for profile tab")
                }
            }
        }
        .onAppear {
            // タブバーの背景スタイルを統一（半透明のぼかし効果）
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance

            // アプリ起動時にバックグラウンドでプロフィール写真をプリロード
            if let userId = authManager.currentUser?.id {
                AppStateManager.shared.preloadUserPhotos(userId: userId)
                print("🚀 Background preload started for user \(userId)")
            }

            // アプリ起動時にプッシュ通知権限をリクエスト
            requestNotificationPermission()
        }
    }

    // プッシュ通知の権限をリクエスト
    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await NotificationService.shared.requestAuthorization()
                if granted {
                    print("✅ Push notification permission granted")
                } else {
                    print("⚠️ Push notification permission denied")
                }
            } catch {
                print("❌ Failed to request notification permission: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
