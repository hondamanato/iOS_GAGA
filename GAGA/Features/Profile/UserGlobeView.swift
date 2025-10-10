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

    var body: some View {
        ZStack {
            GlobeView(selectedCountry: $selectedCountry, photos: photos)

            if photos.isEmpty {
                VStack {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.6))
                    Text("写真を投稿して\n地球を埋めよう")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                }
            }
        }
        .onAppear {
            loadUserPhotos()
        }
    }

    private func loadUserPhotos() {
        // TODO: Firestoreからユーザーの写真を読み込み
        // FirebaseService.shared.getPhotos(for: userId)
    }
}

#Preview {
    UserGlobeView(userId: "test-user-id")
}
