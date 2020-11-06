//
//  Chapter.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 29/07/2020.
//

import Foundation

struct Chapter: Codable, Hashable {
    let chapterId: String
    let chapterInfo: ChapterData
}

struct ChapterData: Codable, Hashable {
    let chapterId: Int
    let volume: String?
    let chapter: String
    let title: String?
    let langCode: String
    let timestamp: Double?
    
    
    enum CodingKeys: String, CodingKey {
        case chapterId = "id"
        case volume
        case chapter
        case title
        case langCode = "language"
        case timestamp
    }
}

struct PageData: Codable {
    let data: Data
    
    struct Data: Codable {
        let baseURL: String
        let mangaHash: String
        let pages: [String]
        
        enum CodingKeys: String, CodingKey {
            case baseURL = "server"
            case mangaHash = "hash"
            case pages
        }
    }
}
