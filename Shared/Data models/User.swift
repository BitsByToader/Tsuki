//
//  User.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 06.11.2020.
//

struct DecodedUser: Codable {
    let data: User
}

struct User: Codable {
    let profilePicURL: String?
    let username: String
    let joined: Int
    let lastSeen: Int
    let userId: Int
    let premium: Bool
    
    enum CodingKeys: String, CodingKey {
        case profilePicURL = "avatar"
        case username
        case joined
        case lastSeen
        case userId = "id"
        case premium
    }
}
