//
//  Country.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import CoreGraphics

struct Country: Codable, Identifiable {
    let id: String // ISO 3166-1 alpha-2 code (e.g., "JP", "US")
    let name: String
    let nameJa: String?
    var geometry: CountryGeometry?
    var boundingBox: BoundingBox?

    init(id: String, name: String, nameJa: String? = nil) {
        self.id = id
        self.name = name
        self.nameJa = nameJa
        self.geometry = nil
        self.boundingBox = nil
    }

    /// 国旗絵文字を返す（ISO 3166-1 alpha-2コードから生成）
    var flag: String {
        // 国コード（例: "JP", "US", "RU"）を国旗絵文字に変換
        // Unicode Regional Indicator Symbolsを使用
        let base: UInt32 = 127397 // 🇦の基準値 - "A"のUnicode値
        return id.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { String($0) }.joined()
    }
}

struct CountryGeometry: Codable {
    let type: String // "Polygon" or "MultiPolygon"
    let coordinates: [[[Double]]] // GeoJSON format
}

struct BoundingBox: Codable {
    let minLat: Double
    let maxLat: Double
    let minLon: Double
    let maxLon: Double

    var center: (lat: Double, lon: Double) {
        ((minLat + maxLat) / 2, (minLon + maxLon) / 2)
    }
}

extension Country {
    // 国の形状マスクを生成
    func generateMask(size: CGSize) -> CGImage? {
        guard let geometry = geometry,
              let bbox = boundingBox else {
            print("⚠️ Cannot generate mask: missing geometry or bounding box")
            return nil
        }

        let width = Int(size.width)
        let height = Int(size.height)

        // ビットマップコンテキストを作成（白黒）
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            print("❌ Failed to create CGContext")
            return nil
        }

        // 背景を黒で塗りつぶし（マスク外=透明）
        context.setFillColor(gray: 0.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // 国の形状を白で描画（マスク内=不透明）
        context.setFillColor(gray: 1.0, alpha: 1.0)

        // 各ポリゴンリングを描画
        for ring in geometry.coordinates {
            guard ring.count >= 3 else { continue }

            let path = CGMutablePath()
            var isFirst = true

            for point in ring {
                guard point.count >= 2 else { continue }

                let lon = point[0]
                let lat = point[1]

                // 緯度経度を画像座標に変換
                let x = CGFloat((lon - bbox.minLon) / (bbox.maxLon - bbox.minLon)) * CGFloat(width)
                let y = CGFloat((bbox.maxLat - lat) / (bbox.maxLat - bbox.minLat)) * CGFloat(height) // Y軸反転

                if isFirst {
                    path.move(to: CGPoint(x: x, y: y))
                    isFirst = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            path.closeSubpath()
            context.addPath(path)
        }

        context.fillPath()

        // CGImageを生成
        guard let maskImage = context.makeImage() else {
            print("❌ Failed to create mask image")
            return nil
        }

        print("✅ Generated mask for \(name): \(width)x\(height)")
        return maskImage
    }
}
