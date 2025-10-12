//
//  PhotoGridPickerView.swift
//  GAGA
//
//  Created by AI on 2025/10/12.
//

import SwiftUI
import Photos

struct PhotoGridPickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var photoAssets: [PHAsset] = []
    @State private var selectedAsset: PHAsset?

    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            // 選択中の写真プレビュー（4:5比率）
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width - 24, height: (UIScreen.main.bounds.width - 24) * 1.25)
                    .clipped()
                    .cornerRadius(12)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
            }

            // フォトアルバムグリッド
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    // カメラボタン
                    Button(action: {
                        // TODO: カメラを開く
                    }) {
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .frame(width: (UIScreen.main.bounds.width - 6) / 4, height: (UIScreen.main.bounds.width - 6) / 4)
                    }

                    // フォトアルバムの写真
                    ForEach(photoAssets, id: \.localIdentifier) { asset in
                        PhotoThumbnailView(asset: asset, isSelected: selectedAsset == asset)
                            .onTapGesture {
                                selectedAsset = asset
                                loadImage(from: asset)
                            }
                    }
                }
                .padding(.top, 12)
            }
        }
        .onAppear {
            requestPhotoLibraryAccess()
        }
    }

    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                DispatchQueue.main.async {
                    loadPhotos()
                }
            }
        }
    }

    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        photoAssets = assets

        // 最初の写真を自動選択
        if let firstAsset = assets.first {
            selectedAsset = firstAsset
            loadImage(from: firstAsset)
        }
    }

    private func loadImage(from asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                self.selectedImage = image
            }
        }
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: (UIScreen.main.bounds.width - 6) / 4, height: (UIScreen.main.bounds.width - 6) / 4)
                    .clipped()
            } else {
                Color.gray.opacity(0.3)
                    .frame(width: (UIScreen.main.bounds.width - 6) / 4, height: (UIScreen.main.bounds.width - 6) / 4)
            }

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .padding(4)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic

        let size = CGSize(width: 200, height: 200)

        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}

#Preview {
    PhotoGridPickerView(selectedImage: .constant(nil))
}
