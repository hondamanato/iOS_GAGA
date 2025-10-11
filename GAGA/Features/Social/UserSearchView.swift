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
                        .foregroundColor(.black)

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
                                .foregroundColor(.black)
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
                                // プロフィール画像
                                if let imageURL = user.profileImageURL {
                                    AsyncImage(url: URL(string: imageURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                        default:
                                            Circle()
                                                .fill(Color.blue.opacity(0.3))
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(.white)
                                                )
                                        }
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.blue.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.white)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName)
                                        .font(.headline)
                                    Text("@\(user.username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
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

        do {
            searchResults = try await FirebaseService.shared.searchUsers(query: searchText)
        } catch {
            print("❌ Search error: \(error.localizedDescription)")
            searchResults = []
        }

        isSearching = false
    }
}

struct UserDetailView: View {
    let user: User
    @StateObject private var authManager = AuthManager.shared
    @State private var isFollowing = false
    @State private var isLoading = false
    @State private var followerCount: Int
    @State private var followingCount: Int
    @State private var isBlocked = false
    @State private var showBlockConfirmation = false
    @State private var showBlockedMessage = false
    @Environment(\.dismiss) var dismiss

    init(user: User) {
        self.user = user
        _followerCount = State(initialValue: user.followerCount)
        _followingCount = State(initialValue: user.followingCount)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ユーザー情報
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

                    HStack(spacing: 40) {
                        // 訪問国数（タップ不可）
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
                                Text("\(followerCount)")
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
                                Text("\(followingCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("フォロー中")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // フォローボタン（自分自身の場合は非表示）
                    if user.id != authManager.currentUser?.id {
                        Button(action: {
                            Task {
                                await toggleFollow()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text(isFollowing ? "フォロー中" : "フォロー")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFollowing ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                    }
                }

                Divider()

                // ユーザーの地球儀
                UserGlobeView(userId: user.id)
                    .frame(height: 300)

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
            .padding()
        }
        .navigationTitle(user.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 自分以外のユーザーにはメニューを表示
            if user.id != authManager.currentUser?.id {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showBlockConfirmation = true
                        } label: {
                            Label(isBlocked ? "ブロックを解除" : "ブロック", systemImage: "hand.raised.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .task {
            await loadFollowStatus()
            await loadBlockStatus()
        }
        .alert(isBlocked ? "ブロック解除" : "ブロック", isPresented: $showBlockConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button(isBlocked ? "解除" : "ブロック", role: .destructive) {
                Task {
                    await toggleBlock()
                }
            }
        } message: {
            if isBlocked {
                Text("\(user.displayName)のブロックを解除しますか？")
            } else {
                Text("\(user.displayName)をブロックしますか？ブロックすると、お互いのフォロー関係が解除されます。")
            }
        }
        .alert("ブロックしました", isPresented: $showBlockedMessage) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("\(user.displayName)をブロックしました。")
        }
    }

    private func loadFollowStatus() async {
        guard let currentUserId = authManager.currentUser?.id else { return }

        do {
            isFollowing = try await FirebaseService.shared.isFollowing(
                followerId: currentUserId,
                followingId: user.id
            )
        } catch {
            print("❌ Failed to load follow status: \(error)")
        }
    }

    private func toggleFollow() async {
        guard let currentUserId = authManager.currentUser?.id else { return }

        isLoading = true

        do {
            if isFollowing {
                // フォロー解除
                try await FirebaseService.shared.unfollowUser(
                    followerId: currentUserId,
                    followingId: user.id
                )
                isFollowing = false
                followerCount -= 1
                print("✅ Unfollowed user: \(user.displayName)")
            } else {
                // フォロー
                try await FirebaseService.shared.followUser(
                    followerId: currentUserId,
                    followingId: user.id
                )
                isFollowing = true
                followerCount += 1
                print("✅ Followed user: \(user.displayName)")
            }
        } catch {
            print("❌ Follow toggle error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func loadBlockStatus() async {
        guard let currentUserId = authManager.currentUser?.id else { return }

        do {
            isBlocked = try await FirebaseService.shared.isBlocked(
                blockerId: currentUserId,
                blockedId: user.id
            )
        } catch {
            print("❌ Failed to load block status: \(error)")
        }
    }

    private func toggleBlock() async {
        guard let currentUserId = authManager.currentUser?.id else { return }

        do {
            if isBlocked {
                // ブロック解除
                try await FirebaseService.shared.unblockUser(
                    blockerId: currentUserId,
                    blockedId: user.id
                )
                isBlocked = false
                print("✅ Unblocked user: \(user.displayName)")
            } else {
                // ブロック
                try await FirebaseService.shared.blockUser(
                    blockerId: currentUserId,
                    blockedId: user.id
                )
                isBlocked = true
                isFollowing = false
                showBlockedMessage = true
                print("✅ Blocked user: \(user.displayName)")
            }
        } catch {
            print("❌ Block toggle error: \(error.localizedDescription)")
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

#Preview {
    UserSearchView()
}
