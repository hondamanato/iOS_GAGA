//
//  User.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var displayName: String
    var email: String?
    var profileImageURL: String?
    var visitedCountries: [String] // Country codes
    var followerCount: Int
    var followingCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(id: String, displayName: String, email: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.profileImageURL = nil
        self.visitedCountries = []
        self.followerCount = 0
        self.followingCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
