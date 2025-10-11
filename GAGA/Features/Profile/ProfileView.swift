//
//  ProfileView.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var refreshID = UUID()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // プロフィールヘッダー
                    if let user = authManager.currentUser {
                        VStack(spacing: 12) {
                            // プロフィール画像
                            if let imageURL = user.profileImageURL {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    default:
                                        Circle()
                                            .fill(Color.blue.opacity(0.3))
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                    )
                            }

                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // 統計情報
                            HStack(spacing: 40) {
                                // 訪問国数（タップ不可、スクロールで移動）
                                VStack {
                                    Text("\(user.visitedCountries.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("訪問国")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                // フォロワー数（タップ可能）
                                NavigationLink(destination: FollowListView(userId: user.id, listType: .followers)) {
                                    VStack {
                                        Text("\(user.followerCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        Text("フォロワー")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                // フォロー中数（タップ可能）
                                NavigationLink(destination: FollowListView(userId: user.id, listType: .following)) {
                                    VStack {
                                        Text("\(user.followingCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        Text("フォロー中")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                        }
                        .padding()

                        Divider()

                        // 自分の地球儀
                        VStack(alignment: .leading, spacing: 12) {
                            Text("マイ地球儀")
                                .font(.headline)
                                .padding(.horizontal)

                            UserGlobeView(userId: user.id)
                                .frame(height: 300)
                                .id(refreshID)
                        }

                        Divider()

                        // 訪問国リスト
                        VStack(alignment: .leading, spacing: 12) {
                            Text("訪問した国")
                                .font(.headline)
                                .padding(.horizontal)

                            if user.visitedCountries.isEmpty {
                                Text("まだ訪問した国がありません")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                // 訪問国を横スクロールで表示
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(getVisitedCountries(user.visitedCountries)) { country in
                                            VStack(spacing: 8) {
                                                Text(country.flag)
                                                    .font(.system(size: 50))
                                                Text(country.nameJa ?? country.name)
                                                    .font(.caption)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 80)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.black)
                    }
                }
            }
            .task {
                // プロフィール表示時にユーザー情報を再読み込み
                await refreshUserData()
            }
            .refreshable {
                // プルして更新
                await refreshUserData()
            }
        }
    }

    private func refreshUserData() async {
        guard let userId = authManager.currentUser?.id else { return }

        do {
            let user = try await FirebaseService.shared.getUser(userId: userId)
            await MainActor.run {
                authManager.currentUser = user
                refreshID = UUID() // UserGlobeViewを強制的に再読み込み
                print("✅ Profile data refreshed: \(user.visitedCountries.count) countries")
            }
        } catch {
            print("❌ Failed to refresh user data: \(error)")
        }
    }

    /// 訪問国コードからCountryオブジェクトのリストを取得
    private func getVisitedCountries(_ countryCodes: [String]) -> [Country] {
        let allCountries = GeoDataManager.shared.getAllCountries()
        let countryDict = Dictionary(uniqueKeysWithValues: allCountries.map { ($0.id, $0) })

        return countryCodes.compactMap { countryDict[$0] }
            .sorted { ($0.nameJa ?? $0.name) < ($1.nameJa ?? $1.name) } // 名前順にソート
    }
}

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false

    var body: some View {
        List {
            // ユーザーアカウント情報
            if let user = authManager.currentUser {
                Section {
                    NavigationLink(destination: ProfileEditView()) {
                        HStack(spacing: 16) {
                            // プロフィール画像
                            if let imageURL = user.profileImageURL {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    default:
                                        Circle()
                                            .fill(Color.blue.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    )
                            }

                            // ユーザー情報
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if let email = user.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            // アプリ設定
            Section("アプリ設定") {
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("通知", systemImage: "bell.fill")
                        .foregroundColor(.black)
                }

                NavigationLink(destination: BlockedUsersListView()) {
                    Label("ブロックリスト", systemImage: "hand.raised.fill")
                        .foregroundColor(.black)
                }

                NavigationLink(destination: Text("プライバシー設定画面（未実装）")) {
                    Label("プライバシー", systemImage: "lock.fill")
                        .foregroundColor(.black)
                }

                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Label("言語", systemImage: "globe")
                            .foregroundColor(.black)
                        Spacer()
                        Text(Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "ja") ?? "日本語")
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            }

            // その他
            Section("その他") {
                NavigationLink(destination: Text("利用規約画面（未実装）")) {
                    Label("利用規約", systemImage: "doc.text")
                        .foregroundColor(.black)
                }

                NavigationLink(destination: Text("プライバシーポリシー画面（未実装）")) {
                    Label("プライバシーポリシー", systemImage: "shield")
                        .foregroundColor(.black)
                }

                NavigationLink(destination: Text("お問い合わせ画面（未実装）")) {
                    Label("お問い合わせ", systemImage: "envelope.circle")
                        .foregroundColor(.black)
                }

                HStack {
                    Label("バージョン", systemImage: "info.circle")
                        .foregroundColor(.black)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }

            // アカウント管理
            Section {
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("ログアウト")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .foregroundColor(.red)

                Button(action: {
                    showDeleteAccountAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("アカウント削除")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("ログアウト", isPresented: $showLogoutAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("ログアウト", role: .destructive) {
                try? authManager.signOut()
            }
        } message: {
            Text("ログアウトしてもよろしいですか？")
        }
        .alert("アカウント削除", isPresented: $showDeleteAccountAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                // TODO: アカウント削除処理を実装
                print("⚠️ Account deletion not implemented yet")
            }
        } message: {
            Text("アカウントを削除すると、すべてのデータが失われます。この操作は取り消せません。")
        }
    }
}

#Preview {
    ProfileView()
}
