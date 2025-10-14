//
//  PhotoComposerView.swift
//  GAGA
//
//  Created by AI on 2025/10/12.
//

import SwiftUI

struct PhotoComposerView: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedCountry: Country?
    @Environment(\.presentationMode) var presentationMode
    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 0) {
            // 写真選択グリッド
            PhotoGridPickerView(selectedImage: $selectedImage)
        }
        .navigationTitle(selectedCountry?.nameJa ?? selectedCountry?.name ?? "写真を投稿")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await uploadPhoto()
                    }
                }) {
                    if isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text("投稿")
                            .fontWeight(.semibold)
                            .foregroundColor(selectedImage != nil ? .blue : .gray)
                    }
                }
                .disabled(selectedImage == nil || isUploading)
            }
        }
    }

    private func uploadPhoto() async {
        guard let image = selectedImage,
              let country = selectedCountry,
              let userId = AuthManager.shared.currentUser?.id else {
            print("❌ Missing required data for upload")
            return
        }

        isUploading = true

        do {
            print("🚀 Starting photo upload process...")

            // 1. 画像を3サイズに処理
            let processor = PhotoProcessor()
            guard let photoSizes = processor.processPhotoForUpload(image),
                  let originalData = photoSizes.original,
                  let mediumData = photoSizes.medium,
                  let thumbnailData = photoSizes.thumbnail else {
                print("❌ Failed to process image")
                isUploading = false
                return
            }

            print("✅ Image processed: original=\(originalData.count)bytes, medium=\(mediumData.count)bytes, thumbnail=\(thumbnailData.count)bytes")

            // 2. Firebase Storageにアップロード
            let result = try await PhotoUploader.shared.uploadPhotoSet(
                original: originalData,
                medium: mediumData,
                thumbnail: thumbnailData,
                userId: userId,
                countryCode: country.id
            )

            print("✅ Photos uploaded to Storage")

            // 3. Firestoreに写真情報を保存
            let photo = Photo(
                id: result.photoId,
                userId: userId,
                countryCode: country.id,
                imageURL: result.medium,
                thumbnailURL: result.thumbnail,
                originalURL: result.original,
                createdAt: Date()
            )

            try await FirebaseService.shared.savePhoto(photo)

            print("✅ Photo metadata saved to Firestore")

            // 4. ユーザーの訪問国リストを更新
            try await FirebaseService.shared.addVisitedCountry(userId: userId, countryCode: country.id)

            // 5. AuthManagerのcurrentUserも更新
            if var currentUser = AuthManager.shared.currentUser {
                if !currentUser.visitedCountries.contains(country.id) {
                    currentUser.visitedCountries.append(country.id)
                    currentUser.updatedAt = Date()
                    await MainActor.run {
                        AuthManager.shared.currentUser = currentUser
                    }
                }
            }

            print("🎉 Upload complete!")

            // 6. 画面を閉じる
            await MainActor.run {
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            print("❌ Upload error: \(error.localizedDescription)")
            // TODO: エラーメッセージをユーザーに表示
        }

        isUploading = false
    }
}

#Preview {
    PhotoComposerView(
        selectedImage: .constant(nil),
        selectedCountry: .constant(Country(id: "JP", name: "Japan", nameJa: "日本"))
    )
}
