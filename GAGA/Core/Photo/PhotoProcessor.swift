//
//  PhotoProcessor.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import UIKit
import CoreImage

class PhotoProcessor {
    private let context = CIContext()

    // 写真を国の形にマスキング
    func maskPhotoToCountry(_ photo: UIImage, country: Country) -> UIImage? {
        guard let mask = country.generateMask(size: photo.size) else {
            return nil
        }

        // UIImageをCIImageに変換
        guard let photoCI = CIImage(image: photo) else {
            return nil
        }

        let maskCI = CIImage(cgImage: mask)

        // CIFilterを正しい方法で作成
        guard let filter = CIFilter(name: "CIBlendWithAlphaMask") else {
            return nil
        }

        // パラメータを設定
        filter.setValue(photoCI, forKey: kCIInputImageKey)
        filter.setValue(maskCI, forKey: kCIInputMaskImageKey)
        filter.setValue(CIImage(color: .clear).cropped(to: photoCI.extent), forKey: kCIInputBackgroundImageKey)

        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // 写真を圧縮（アップロード用）
    func compressImage(_ image: UIImage, maxSizeKB: Int = 2048) -> Data? {
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxSizeKB * 1024, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        return imageData
    }

    // サムネイル生成
    func createThumbnail(_ image: UIImage, size: CGSize = CGSize(width: 256, height: 256)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // 3サイズの画像を生成
    func processPhotoForUpload(_ image: UIImage) -> (original: Data?, medium: Data?, thumbnail: Data?)? {
        // オリジナル（最大2MB）
        let original = compressImage(image, maxSizeKB: 2048)

        // 中サイズ（1MB、1024x1024以下）
        let mediumSize = CGSize(width: 1024, height: 1024)
        let mediumImage = resizeImage(image, targetSize: mediumSize)
        let medium = compressImage(mediumImage, maxSizeKB: 1024)

        // サムネイル（256KB、256x256）
        let thumbnailImage = createThumbnail(image)
        let thumbnail = thumbnailImage.flatMap { compressImage($0, maxSizeKB: 256) }

        return (original, medium, thumbnail)
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
