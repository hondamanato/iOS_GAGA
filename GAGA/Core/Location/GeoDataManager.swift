//
//  GeoDataManager.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation

// MARK: - GeoJSON Models

struct GeoJSONFeatureCollection: Codable {
    let type: String
    let features: [GeoJSONFeature]
}

struct GeoJSONFeature: Codable {
    let type: String
    let properties: GeoJSONProperties
    let geometry: GeoJSONGeometry
}

struct GeoJSONProperties: Codable {
    let name: String?
    let isoA2: String?
    let nameJa: String?

    enum CodingKeys: String, CodingKey {
        case name = "NAME"
        case isoA2 = "ISO_A2"
        case nameJa = "NAME_JA"
    }
}

struct GeoJSONGeometry: Codable {
    let type: String
    let coordinates: GeoJSONCoordinates

    enum GeoJSONCoordinates: Codable {
        case polygon([[[Double]]])
        case multiPolygon([[[[Double]]]])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let multiPoly = try? container.decode([[[[Double]]]].self) {
                self = .multiPolygon(multiPoly)
            } else if let poly = try? container.decode([[[Double]]].self) {
                self = .polygon(poly)
            } else {
                throw DecodingError.typeMismatch(
                    GeoJSONCoordinates.self,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid geometry")
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .polygon(let coords):
                try container.encode(coords)
            case .multiPolygon(let coords):
                try container.encode(coords)
            }
        }
    }
}

// MARK: - GeoDataManager

class GeoDataManager {
    static let shared = GeoDataManager()

    private var countries: [String: Country] = [:]
    private var regions: [String: Region] = [:]

    private init() {
        loadGeoData()
    }

    // GeoJSONファイルから地理データを読み込み
    private func loadGeoData() {
        guard let url = Bundle.main.url(forResource: "ne_50m_admin_0_countries_lakes", withExtension: "geojson") else {
            print("⚠️ GeoJSONファイルが見つかりません。サンプルデータを使用します。")
            loadSampleCountries()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let countriesArray = try parseGeoJSON(data: data)

            // Dictionary に変換
            for country in countriesArray {
                countries[country.id] = country
            }

            print("✅ GeoJSONから\(countries.count)カ国のデータを読み込みました")
        } catch {
            print("❌ GeoJSON読み込みエラー: \(error)")
            loadSampleCountries()
        }
    }

    // サンプル国データ（開発用・フォールバック）
    private func loadSampleCountries() {
        let japan = Country(
            id: "JP",
            name: "Japan",
            nameJa: "日本"
        )

        let usa = Country(
            id: "US",
            name: "United States",
            nameJa: "アメリカ合衆国"
        )

        let france = Country(
            id: "FR",
            name: "France",
            nameJa: "フランス"
        )

        countries = [
            "JP": japan,
            "US": usa,
            "FR": france
        ]

        print("ℹ️ サンプルデータ(\(countries.count)カ国)を使用します")
    }

    // 国コードから国を取得
    func getCountry(code: String) -> Country? {
        return countries[code]
    }

    // 全国リストを取得
    func getAllCountries() -> [Country] {
        return Array(countries.values)
    }

    // GeoJSONをパース
    private func parseGeoJSON(data: Data) throws -> [Country] {
        let decoder = JSONDecoder()
        let featureCollection = try decoder.decode(GeoJSONFeatureCollection.self, from: data)

        return featureCollection.features.compactMap { feature -> Country? in
            guard let name = feature.properties.name,
                  let isoCode = feature.properties.isoA2,
                  !isoCode.isEmpty,
                  isoCode != "-99" else {  // Natural Earthで無効な国コードを除外
                return nil
            }

            var country = Country(
                id: isoCode,
                name: name,
                nameJa: feature.properties.nameJa
            )

            // ジオメトリを設定
            let geometryType = feature.geometry.type

            switch feature.geometry.coordinates {
            case .polygon(let coords):
                country.geometry = CountryGeometry(type: "Polygon", coordinates: coords)
            case .multiPolygon(let coords):
                country.geometry = CountryGeometry(type: "MultiPolygon", coordinates: coords.flatMap { $0 })
            }

            // バウンディングボックスを計算
            country.boundingBox = calculateBoundingBox(for: country.geometry)

            return country
        }
    }

    // バウンディングボックスを計算
    private func calculateBoundingBox(for geometry: CountryGeometry?) -> BoundingBox? {
        guard let geometry = geometry else { return nil }

        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude

        for ring in geometry.coordinates {
            for point in ring {
                guard point.count >= 2 else { continue }
                let lon = point[0]
                let lat = point[1]

                minLon = min(minLon, lon)
                maxLon = max(maxLon, lon)
                minLat = min(minLat, lat)
                maxLat = max(maxLat, lat)
            }
        }

        return BoundingBox(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
}
