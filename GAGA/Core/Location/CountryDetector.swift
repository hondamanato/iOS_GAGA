//
//  CountryDetector.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import CoreLocation

class CountryDetector {
    static let shared = CountryDetector()

    private var countries: [Country] = []

    private init() {
        loadCountries()
    }

    // GeoDataManagerから地理データを読み込み
    private func loadCountries() {
        countries = GeoDataManager.shared.getAllCountries()
        print("🔍 CountryDetector: Loaded \(countries.count) countries for detection")
    }

    // 緯度経度から国を特定（Point-in-Polygon判定）
    func detectCountry(latitude: Double, longitude: Double) -> Country? {
        // まずバウンディングボックスでフィルタリング（高速化）
        let candidates = countries.filter { country in
            guard let bbox = country.boundingBox else { return false }
            return latitude >= bbox.minLat && latitude <= bbox.maxLat &&
                   longitude >= bbox.minLon && longitude <= bbox.maxLon
        }

        // Point-in-Polygon判定で正確な国を特定
        for country in candidates {
            guard let geometry = country.geometry else { continue }

            for ring in geometry.coordinates {
                if isPointInPolygon(latitude: latitude, longitude: longitude, polygon: ring) {
                    print("✅ Detected country: \(country.name) (\(country.id)) at (\(latitude), \(longitude))")
                    return country
                }
            }
        }

        print("⚠️ No country found at (\(latitude), \(longitude))")
        return nil
    }

    // Point-in-Polygon判定（Ray Casting Algorithm）
    private func isPointInPolygon(latitude: Double, longitude: Double, polygon: [[Double]]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            guard polygon[i].count >= 2, polygon[j].count >= 2 else {
                j = i
                continue
            }

            let xi = polygon[i][0]  // longitude
            let yi = polygon[i][1]  // latitude
            let xj = polygon[j][0]
            let yj = polygon[j][1]

            // Ray casting: 点から右方向に伸ばした線が、ポリゴンの辺と交差する回数を数える
            let intersect = ((yi > latitude) != (yj > latitude)) &&
                           (longitude < (xj - xi) * (latitude - yi) / (yj - yi) + xi)

            if intersect {
                inside.toggle()
            }

            j = i
        }

        return inside
    }

    // タップ位置（3D座標）から国を特定
    func detectCountryFromVector(x: Float, y: Float, z: Float) -> Country? {
        // 3D座標を緯度経度に変換（SceneKitの座標系に対応）
        let radius = sqrt(x * x + y * y + z * z)
        let lat = asin(y / radius) * 180.0 / .pi
        let lon = atan2(x, z) * 180.0 / .pi

        return detectCountry(latitude: Double(lat), longitude: Double(lon))
    }
}
