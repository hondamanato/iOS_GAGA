//
//  EquirectangularTexture.swift
//  GAGA
//
//  Created by AI on 2025/10/10.
//

import Foundation
import UIKit
import CoreGraphics

/// Equirectangular投影を使って世界地図テクスチャを生成・管理するクラス
class EquirectangularTexture {
    // テクスチャサイズ（2048x1024が標準、4096x2048が高解像度）
    private let textureSize: CGSize
    private var currentTexture: UIImage?

    init(textureSize: CGSize = CGSize(width: 2048, height: 1024)) {
        self.textureSize = textureSize
        self.currentTexture = createBaseTexture()
    }

    // MARK: - 座標変換

    /// 緯度経度をEquirectangularテクスチャ上のXY座標に変換
    /// - Parameters:
    ///   - latitude: 緯度（-90°〜90°）
    ///   - longitude: 経度（-180°〜180°）
    /// - Returns: テクスチャ上のピクセル座標
    func latLonToTextureCoordinates(latitude: Double, longitude: Double) -> CGPoint {
        // Equirectangular投影の公式
        // X = (経度 + 180) / 360 * 幅
        // Y = (90 - 緯度) / 180 * 高さ

        let x = (longitude + 180.0) / 360.0 * textureSize.width
        let y = (90.0 - latitude) / 180.0 * textureSize.height

        return CGPoint(x: x, y: y)
    }

    /// BoundingBoxをテクスチャ上の矩形に変換
    func boundingBoxToTextureRect(bbox: BoundingBox) -> CGRect {
        let topLeft = latLonToTextureCoordinates(latitude: bbox.maxLat, longitude: bbox.minLon)
        let bottomRight = latLonToTextureCoordinates(latitude: bbox.minLat, longitude: bbox.maxLon)

        let width = bottomRight.x - topLeft.x
        let height = bottomRight.y - topLeft.y

        return CGRect(x: topLeft.x, y: topLeft.y, width: width, height: height)
    }

    // MARK: - テクスチャ生成

    /// ベース白地図テクスチャを作成
    private func createBaseTexture() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: textureSize)

        return renderer.image { context in
            // 青い海の背景
            UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: textureSize))
        }
    }

    // MARK: - テクスチャ合成

    /// 写真を世界地図テクスチャに合成（国の形でマスキング）
    /// - Parameters:
    ///   - photo: 元の写真（マスキングはこのメソッド内で行う）
    ///   - country: 国情報（BoundingBoxとGeometryを含む）
    ///   - baseTexture: ベーステクスチャ（指定しない場合はcurrentTextureを使用）
    /// - Returns: 更新されたテクスチャ
    func compositePhotoToTexture(
        photo: UIImage,
        country: Country,
        baseTexture: UIImage? = nil
    ) -> UIImage? {
        guard let bbox = country.boundingBox else {
            print("⚠️ Country \(country.name) has no bounding box")
            return currentTexture
        }

        // ベーステクスチャを決定
        let base = baseTexture ?? currentTexture ?? createBaseTexture()

        // 国のBoundingBoxをテクスチャ座標に変換
        let textureRect = boundingBoxToTextureRect(bbox: bbox)

        print("📍 Placing \(country.name) photo at texture coordinates: \(textureRect)")

        // 現在のテクスチャに写真を合成（国の形でマスキング）
        guard let newTexture = compositeSinglePhoto(
            baseTexture: base,
            photo: photo,
            at: textureRect,
            country: country
        ) else {
            print("❌ Failed to composite photo for \(country.name)")
            return base
        }

        currentTexture = newTexture
        return newTexture
    }

    /// 複数の写真を一度に合成
    func compositeMultiplePhotos(photos: [String: (image: UIImage, country: Country)]) -> UIImage? {
        var texture = currentTexture ?? createBaseTexture()

        // まず全ての国を白で描画
        texture = drawCountriesToTexture(texture)

        for (countryCode, photoData) in photos {
            guard let bbox = photoData.country.boundingBox else {
                print("⚠️ Skipping \(countryCode): no bounding box")
                continue
            }

            let textureRect = boundingBoxToTextureRect(bbox: bbox)

            if let newTexture = compositeSinglePhoto(
                baseTexture: texture,
                photo: photoData.image,
                at: textureRect,
                country: photoData.country
            ) {
                texture = newTexture
                print("✅ Composited photo for \(photoData.country.name)")
            }
        }

        currentTexture = texture
        return texture
    }

    /// 単一の写真をテクスチャに合成する内部メソッド（国の形でマスキング）
    private func compositeSinglePhoto(baseTexture: UIImage, photo: UIImage, at rect: CGRect, country: Country) -> UIImage? {
        guard let geometry = country.geometry else {
            print("  ⚠️ Country \(country.name) has no geometry")
            return baseTexture
        }

        // デバッグログ：サイズと座標を出力
        print("🖼 Compositing photo with country mask:")
        print("  📏 Photo size: \(photo.size.width)×\(photo.size.height)")
        print("  📍 Target rect: (\(rect.origin.x), \(rect.origin.y)) size: \(rect.size.width)×\(rect.size.height)")
        print("  🗺 Texture size: \(textureSize.width)×\(textureSize.height)")

        // 境界チェック：rectがテクスチャサイズを超えないようにクリッピング
        let clippedRect = rect.intersection(CGRect(origin: .zero, size: textureSize))

        if clippedRect.isEmpty {
            print("  ⚠️ Warning: Rect is outside texture bounds")
            return baseTexture
        }

        // 写真をrectのサイズにリサイズ
        let resizedPhoto = resizeImage(photo, to: clippedRect.size)
        print("  ✂️ Resized photo to: \(resizedPhoto.size.width)×\(resizedPhoto.size.height)")

        // 透明度を保持するフォーマットを設定
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: textureSize, format: format)

        return renderer.image { context in
            // 1. ベーステクスチャを描画
            baseTexture.draw(in: CGRect(origin: .zero, size: textureSize))

            // 2. 国の形状をクリッピングパスとして作成（Equirectangular座標系）
            let cgContext = context.cgContext
            cgContext.saveGState()

            for ring in geometry.coordinates {
                guard ring.count >= 3 else { continue }

                let path = CGMutablePath()
                var isFirst = true

                for point in ring {
                    guard point.count >= 2 else { continue }
                    let lon = point[0]
                    let lat = point[1]

                    // 緯度経度をEquirectangularテクスチャ座標に変換
                    let texturePoint = latLonToTextureCoordinates(latitude: lat, longitude: lon)

                    if isFirst {
                        path.move(to: texturePoint)
                        isFirst = false
                    } else {
                        path.addLine(to: texturePoint)
                    }
                }

                path.closeSubpath()
                cgContext.addPath(path)
            }

            // 3. クリッピングパスを適用
            cgContext.clip()

            // 4. クリッピングされた領域内に写真を描画
            resizedPhoto.draw(in: clippedRect)

            cgContext.restoreGState()

            print("  ✅ Photo composited successfully with country mask")
        }
    }

    /// 画像をリサイズするヘルパーメソッド（透明度を保持）
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false // 透明度を保持

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - 陸地描画

    /// GeoJSONの全ての国を白で塗りつぶし、国境線を黒で描画
    func drawCountriesToTexture(_ baseTexture: UIImage) -> UIImage {
        print("🗺 Drawing all countries to texture...")

        let renderer = UIGraphicsImageRenderer(size: textureSize)

        return renderer.image { context in
            // 1. まず青い海を描画
            UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: textureSize))

            // 2. 全ての国を取得
            let countries = GeoDataManager.shared.getAllCountries()
            print("  📍 Found \(countries.count) countries to draw")

            // 3. 各国を白で塗りつぶす
            UIColor.white.setFill()

            var drawnCount = 0
            var borderPaths: [CGPath] = [] // 国境線のパスを保存

            for country in countries {
                guard let geometry = country.geometry else { continue }

                // 各ポリゴンを描画
                for ring in geometry.coordinates {
                    guard ring.count >= 3 else { continue }

                    let path = CGMutablePath()
                    var isFirst = true

                    for point in ring {
                        guard point.count >= 2 else { continue }

                        let lon = point[0]
                        let lat = point[1]

                        // 緯度経度をテクスチャ座標に変換
                        let texturePoint = latLonToTextureCoordinates(latitude: lat, longitude: lon)

                        if isFirst {
                            path.move(to: texturePoint)
                            isFirst = false
                        } else {
                            path.addLine(to: texturePoint)
                        }
                    }

                    path.closeSubpath()
                    context.cgContext.addPath(path)

                    // 国境線用にパスを保存
                    borderPaths.append(path)
                }

                drawnCount += 1
            }

            // 一度にすべてのパスを塗りつぶす（白い陸地）
            context.cgContext.fillPath()
            print("  ✅ Drew \(drawnCount) countries in white")

            // 4. 国境線を黒で描画
            context.cgContext.setStrokeColor(UIColor(white: 0.0, alpha: 0.6).cgColor)
            context.cgContext.setLineWidth(0.5) // 細い線

            for path in borderPaths {
                context.cgContext.addPath(path)
            }

            context.cgContext.strokePath()
            print("  ✅ Drew country borders in black")
        }
    }

    // MARK: - テクスチャ取得

    /// 現在のテクスチャを取得
    func getCurrentTexture() -> UIImage? {
        return currentTexture
    }

    /// テクスチャをリセット
    func resetTexture() {
        currentTexture = createBaseTexture()
    }
}

// MARK: - Extension for debugging

extension EquirectangularTexture {
    /// デバッグ用：座標変換のテスト
    func debugCoordinateConversion() {
        print("🔍 Debug: Coordinate Conversion Tests")

        // 東京
        let tokyo = latLonToTextureCoordinates(latitude: 35.6762, longitude: 139.6503)
        print("  東京 (35.68°N, 139.65°E) → (\(Int(tokyo.x)), \(Int(tokyo.y)))")

        // ニューヨーク
        let nyc = latLonToTextureCoordinates(latitude: 40.7128, longitude: -74.0060)
        print("  NYC (40.71°N, -74.01°E) → (\(Int(nyc.x)), \(Int(nyc.y)))")

        // ロンドン
        let london = latLonToTextureCoordinates(latitude: 51.5074, longitude: -0.1278)
        print("  London (51.51°N, -0.13°E) → (\(Int(london.x)), \(Int(london.y)))")

        // 赤道・本初子午線
        let zero = latLonToTextureCoordinates(latitude: 0, longitude: 0)
        print("  赤道・本初子午線 (0°, 0°) → (\(Int(zero.x)), \(Int(zero.y)))")
    }
}
