//
//  ProfileView.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // プロフィールヘッダー
                    if let user = authManager.currentUser {
                        VStack(spacing: 12) {
                            // プロフィール画像
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                )

                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)

                            if let email = user.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // 統計情報
                            HStack(spacing: 40) {
                                VStack {
                                    Text("\(user.visitedCountries.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("訪問国")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                VStack {
                                    Text("\(user.followerCount)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("フォロワー")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                VStack {
                                    Text("\(user.followingCount)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("フォロー中")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                                // TODO: 訪問国リスト表示
                            }
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section("アカウント") {
                    Button("ログアウト") {
                        try? authManager.signOut()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
