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

    // 3:4 比率でクロップ（中央を切り取り）
    func cropToAspectRatio(_ image: UIImage, aspectWidth: CGFloat, aspectHeight: CGFloat) -> UIImage {
        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height
        let targetAspect = aspectWidth / aspectHeight

        var cropRect: CGRect

        if imageAspect > targetAspect {
            // 横長の画像：幅を削る
            let newWidth = imageSize.height * targetAspect
            let xOffset = (imageSize.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageSize.height)
        } else {
            // 縦長の画像：高さを削る
            let newHeight = imageSize.width / targetAspect
            let yOffset = (imageSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: newHeight)
        }

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // 3サイズの画像を生成（3:4 比率に統一）
    func processPhotoForUpload(_ image: UIImage) -> (original: Data?, medium: Data?, thumbnail: Data?)? {
        // まず 3:4 比率にクロップ
        let croppedImage = cropToAspectRatio(image, aspectWidth: 3, aspectHeight: 4)

        // オリジナル（810x1080、最大2MB）
        let originalSize = CGSize(width: 810, height: 1080)
        let originalImage = resizeImage(croppedImage, targetSize: originalSize)
        let original = compressImage(originalImage, maxSizeKB: 2048)

        // 中サイズ（600x800、最大1MB）
        let mediumSize = CGSize(width: 600, height: 800)
        let mediumImage = resizeImage(croppedImage, targetSize: mediumSize)
        let medium = compressImage(mediumImage, maxSizeKB: 1024)

        // サムネイル（192x256、最大256KB）
        let thumbnailSize = CGSize(width: 192, height: 256)
        let thumbnailImage = resizeImage(croppedImage, targetSize: thumbnailSize)
        let thumbnail = compressImage(thumbnailImage, maxSizeKB: 256)

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
