//
//  GlobeMaterial.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import SceneKit
import UIKit

class GlobeMaterial {
    // 基本テクスチャを作成
    static func createBaseMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = createBaseTexture()
        material.specular.contents = UIColor.white
        material.shininess = 0.1
        material.isDoubleSided = false
        return material
    }

    // ベース地球テクスチャ（単色）
    private static func createBaseTexture() -> UIImage {
        let size = CGSize(width: 2048, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 海の色
            UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    // 写真を国の形にマスキングしてテクスチャに合成（非推奨：createPhotoAtlasを使用）
    @available(*, deprecated, message: "Use createPhotoAtlas instead")
    static func updateTextureWithPhoto(_ baseTexture: UIImage, photo: Photo, country: Country) -> UIImage? {
        print("⚠️ updateTextureWithPhoto is deprecated. Use createPhotoAtlas instead.")
        return baseTexture
    }

    // テクスチャアトラスを作成（複数国の写真を1枚のテクスチャに）
    static func createPhotoAtlas(photos: [String: Photo], countries: [String: Country]) async -> UIImage? {
        let equirectangular = EquirectangularTexture(textureSize: CGSize(width: 2048, height: 1024))

        // 写真データを収集
        var photoData: [String: (image: UIImage, country: Country)] = [:]

        for (countryCode, photo) in photos {
            guard let country = countries[countryCode] else {
                print("⚠️ Country not found: \(countryCode)")
                continue
            }

            // 写真をダウンロード
            guard let imageURL = URL(string: photo.imageURL),
                  let (data, _) = try? await URLSession.shared.data(from: imageURL),
                  let image = UIImage(data: data) else {
                print("❌ Failed to download image for \(countryCode)")
                continue
            }

            // マスキングはEquirectangularTexture側で行うため、元の写真をそのまま渡す
            photoData[countryCode] = (image: image, country: country)
            print("✅ Prepared photo for \(country.name)")
        }

        // 複数の写真を一度に合成
        guard let atlas = equirectangular.compositeMultiplePhotos(photos: photoData) else {
            print("❌ Failed to create photo atlas")
            return nil
        }

        print("🎉 Photo atlas created successfully with \(photoData.count) countries")
        return atlas
    }

    // 単一の写真をテクスチャに追加（差分更新用）
    static func addPhotoToTexture(
        _ baseTexture: UIImage,
        photo: UIImage,
        country: Country
    ) -> UIImage? {
        let equirectangular = EquirectangularTexture(textureSize: baseTexture.size)

        // マスキングはEquirectangularTexture側で行うため、元の写真をそのまま渡す
        return equirectangular.compositePhotoToTexture(
            photo: photo,
            country: country,
            baseTexture: baseTexture
        )
    }
}
