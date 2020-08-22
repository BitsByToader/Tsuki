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
    let volume: String?
    let chapter: String?
    let title: String?
    let langCode: String?
    let timestamp: Double?
    
    
    enum CodingKeys: String, CodingKey {
        case volume
        case chapter
        case title
        case langCode = "lang_code"
        case timestamp
    }
}

struct PageData: Codable {
    let baseURL: String
    let mangaHash: String
    let pages: [String]
    
    enum CodingKeys: String, CodingKey {
        case baseURL = "server"
        case mangaHash = "hash"
        case pages = "page_array"
    }
}
