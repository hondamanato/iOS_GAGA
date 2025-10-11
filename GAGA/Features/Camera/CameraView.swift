//
//  CameraView.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import SwiftUI

struct CameraView: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedCountry: Country?
    @Environment(\.presentationMode) var presentationMode
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var isUploading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let country = selectedCountry {
                    Text("\(country.nameJa ?? country.name)の写真を選択")
                        .font(.title2)
                        .padding()
                }

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 400)
                        .overlay(
                            Text("写真を選択してください")
                                .foregroundColor(.secondary)
                        )
                }

                HStack(spacing: 20) {
                    Button(action: {
                        showCamera = true
                    }) {
                        Label("カメラ", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }

                    Button(action: {
                        showPhotoPicker = true
                    }) {
                        Label("ライブラリ", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }
                }

                if selectedImage != nil {
                    Button(action: {
                        Task {
                            await uploadPhoto()
                        }
                    }) {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("投稿する")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isUploading)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("写真投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectedImage: $selectedImage)
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
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("❌ Upload error: \(error.localizedDescription)")
            // TODO: エラーメッセージをユーザーに表示
        }

        isUploading = false
    }
}

#Preview {
    CameraView(
        selectedImage: .constant(nil),
        selectedCountry: .constant(Country(id: "JP", name: "Japan", nameJa: "日本"))
    )
}
