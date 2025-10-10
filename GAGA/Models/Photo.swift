//
//  Photo.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import CoreLocation

struct Photo: Codable, Identifiable {
    let id: String
    let userId: String
    let countryCode: String
    let imageURL: String
    let thumbnailURL: String
    let originalURL: String?
    var location: GeoLocation?
    var caption: String?
    var likeCount: Int
    var commentCount: Int
    let createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, userId: String, countryCode: String, imageURL: String, thumbnailURL: String, originalURL: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.countryCode = countryCode
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.originalURL = originalURL
        self.location = nil
        self.caption = nil
        self.likeCount = 0
        self.commentCount = 0
        self.createdAt = createdAt
        self.updatedAt = Date()
    }
}

struct GeoLocation: Codable {
    let latitude: Double
    let longitude: Double

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
