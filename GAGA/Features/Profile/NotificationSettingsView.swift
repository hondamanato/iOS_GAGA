//
//  NotificationSettingsView.swift
//  GAGA
//
//  Created by AI on 2025/10/11.
//

import SwiftUI

struct NotificationSettingsView: View {
    // 通知設定をUserDefaultsで管理
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("notificationSound") private var notificationSound = true
    @AppStorage("notificationBadge") private var notificationBadge = true

    // 写真関連の通知
    @AppStorage("notifyPhotoComment") private var notifyPhotoComment = true
    @AppStorage("notifyPhotoLike") private var notifyPhotoLike = true

    // フォロー関連の通知
    @AppStorage("notifyNewFollower") private var notifyNewFollower = true
    @AppStorage("notifyFollowingPost") private var notifyFollowingPost = true

    var body: some View {
        List {
            // プッシュ通知全般
            Section {
                Toggle(isOn: $notificationEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("プッシュ通知")
                            .font(.body)
                        Text("すべてのプッシュ通知を受け取る")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if notificationEnabled {
                    Toggle(isOn: $notificationSound) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.black)
                                .frame(width: 24)
                            Text("通知音")
                        }
                    }

                    Toggle(isOn: $notificationBadge) {
                        HStack {
                            Image(systemName: "app.badge.fill")
                                .foregroundColor(.black)
                                .frame(width: 24)
                            Text("バッジ")
                        }
                    }
                }
            } header: {
                Text("通知設定")
            } footer: {
                Text("プッシュ通知をオフにすると、すべての通知が無効になります")
                    .font(.caption)
            }

            // 写真関連の通知
            Section {
                Toggle(isOn: $notifyPhotoComment) {
                    HStack {
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.black)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("コメント")
                                .font(.body)
                            Text("自分の写真にコメントがついた時")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(!notificationEnabled)

                Toggle(isOn: $notifyPhotoLike) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.black)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("いいね")
                                .font(.body)
                            Text("自分の写真にいいねがついた時")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(!notificationEnabled)
            } header: {
                Text("写真")
            }

            // フォロー関連の通知
            Section {
                Toggle(isOn: $notifyNewFollower) {
                    HStack {
                        Image(systemName: "person.badge.plus.fill")
                            .foregroundColor(.black)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("新しいフォロワー")
                                .font(.body)
                            Text("誰かがフォローした時")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(!notificationEnabled)

                Toggle(isOn: $notifyFollowingPost) {
                    HStack {
                        Image(systemName: "photo.badge.plus.fill")
                            .foregroundColor(.black)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("フォロー中の投稿")
                                .font(.body)
                            Text("フォロー中のユーザーが写真を投稿した時")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(!notificationEnabled)
            } header: {
                Text("フォロー")
            }

            // システム設定へのリンク
            Section {
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.black)
                            .frame(width: 24)
                        Text("システム設定を開く")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            } footer: {
                Text("デバイスのシステム設定で通知の詳細設定を変更できます")
                    .font(.caption)
            }
        }
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
}
