//
//  Manga.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 27/07/2020.
//

import Foundation

struct MangaDataModel: Codable {
    let manga: Manga
    var chapters: [Chapter] {
        return chapter.values
    }
    
    var chapter: Chapter.List
}

extension MangaDataModel {
    enum CodingKeys: CodingKey {
        case manga
        case chapter
    }
}

struct Manga: Codable {
    let title: String
    let artist: String
    var coverURL: String
    let description: String
    let rating: Rating
    let tags: [Int]
    
    init( title: String, artist: String, coverURL: String, description: String, rating: Rating, tags: [Int]) {
        self.title = title
        self.artist = artist
        self.coverURL = coverURL
        self.description = description
        self.rating = rating
        self.tags = tags
    }
    
    init(fromDownloadedManga manga: DownloadedManga) {
        title = manga.wrappedMangaTitle
        artist = manga.wrappedMangaArtist
        coverURL = manga.wrappedMangaCoverURL
        description = manga.wrappedMangaDescription
        rating = Rating(bayesian: manga.wrappedMangaRating, users: manga.wrappedUsersRated)
        tags = manga.wrappedMangaTags
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case artist
        case coverURL = "cover_url"
        case description
        case rating
        case tags = "genres"
    }
    
    struct Rating: Codable {
        let bayesian: String
        let users: String
    }
}

struct ReturnedManga: Hashable {
    let title: String
    let coverArtURL: String
    let id: String
}

extension Chapter {
    struct List: Codable {
            let values: [Chapter]

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let dictionary = try container.decode([String : ChapterData].self)

                values = dictionary.map { key, value in
                    Chapter(chapterId: key, chapterInfo: value)
                }
            }
        }
}
