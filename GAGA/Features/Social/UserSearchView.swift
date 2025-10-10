//
//  UserSearchView.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import SwiftUI

struct UserSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false

    var body: some View {
        NavigationView {
            VStack {
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("ユーザーを検索", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { oldValue, newValue in
                            Task {
                                await performSearch()
                            }
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // 検索結果
                if isSearching {
                    ProgressView()
                        .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("ユーザーが見つかりません")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(searchResults) { user in
                        NavigationLink(destination: UserDetailView(user: user)) {
                            HStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )

                                VStack(alignment: .leading) {
                                    Text(user.displayName)
                                        .font(.headline)
                                    Text("\(user.visitedCountries.count)カ国訪問")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("ユーザー検索")
        }
    }

    private func performSearch() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        // TODO: Firestoreでユーザー検索
        // searchResults = await FirebaseService.shared.searchUsers(query: searchText)

        try? await Task.sleep(nanoseconds: 500_000_000)
        searchResults = []

        isSearching = false
    }
}

struct UserDetailView: View {
    let user: User

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ユーザー情報
                VStack(spacing: 12) {
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

                    // フォローボタン
                    Button(action: {
                        // TODO: フォロー処理
                    }) {
                        Text("フォロー")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }

                Divider()

                // ユーザーの地球儀
                UserGlobeView(userId: user.id)
                    .frame(height: 300)
            }
            .padding()
        }
        .navigationTitle(user.displayName)
    }
}

#Preview {
    UserSearchView()
}
