//
//  Manga.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 27/07/2020.
//

import Foundation

struct MangaDataModel: Codable {
    struct Data: Codable {
        var manga: Manga
        var chapters: [ChapterData]
    }
    
    var data: Data
}

struct Manga: Codable {
    let title: String
    let artist: [String]
    var coverURL: String
    let description: String
    let rating: Rating
    let tags: [Int]
    
    init() {
        self.title = ""
        self.artist = [""]
        self.coverURL = ""
        self.description = ""
        self.rating = Rating(bayesian: 1, users: 0)
        self.tags = []
    }
    
    init( title: String, artist: String, coverURL: String, description: String, rating: Rating, tags: [Int]) {
        self.title = title
        self.artist = [artist]
        self.coverURL = coverURL
        self.description = description
        self.rating = rating
        self.tags = tags
    }
    
    init(fromDownloadedManga manga: DownloadedManga) {
        title = manga.wrappedMangaTitle
        artist = [manga.wrappedMangaArtist]
        coverURL = manga.wrappedMangaCoverURL
        description = manga.wrappedMangaDescription
        rating = Rating(bayesian: Float(manga.wrappedMangaRating) ?? 1, users: Int(manga.wrappedUsersRated) ?? 0)
        tags = manga.wrappedMangaTags
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case artist
        case coverURL = "mainCover"
        case description
        case rating
        case tags
    }
    
    struct Rating: Codable {
        let bayesian: Float
        let users: Int
    }
}

struct ReturnedManga: Hashable {
    let title: String
    let coverArtURL: String
    let id: String
}
