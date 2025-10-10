//
//  Region.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation

struct Region: Codable, Identifiable {
    let id: String
    let countryCode: String
    let name: String
    let nameJa: String?
    let level: RegionLevel // 州・県レベル
    var geometry: CountryGeometry?

    init(id: String, countryCode: String, name: String, level: RegionLevel) {
        self.id = id
        self.countryCode = countryCode
        self.name = name
        self.nameJa = nil
        self.level = level
        self.geometry = nil
    }
}

enum RegionLevel: String, Codable {
    case country = "country"
    case state = "state"
    case prefecture = "prefecture"
    case city = "city"
}
