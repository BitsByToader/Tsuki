//
//  Manga.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 27/07/2020.
//

import Foundation

//MARK: - Manga Data Model Struct
struct Manga: Decodable {
    let title: String
    var artist: [String]
    var coverURL: String
    let description: String
    let rating: Rating
    let tags: [String]
    
    init() {
        self.title = ""
        self.artist = [""]
        self.coverURL = ""
        self.description = ""
        self.rating = Rating(bayesian: 1, users: 0)
        self.tags = []
    }
    
    init( title: String, artist: String, coverURL: String, description: String, rating: Rating, tags: [String]) {
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
    
    struct Rating: Codable {
        let bayesian: Float
        let users: Int
    }
    
    //MARK: - JSON Decoding enums and methods.
    enum CodingKeys: String, CodingKey {
        case data, relationships
    }
    
    enum DataCodingKeys: String, CodingKey {
        case attributes
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case title, description, tags
    }
    
    enum TitleCodingKeys: String, CodingKey {
        case en
    }
    
    enum DescriptionCodingKeys: String, CodingKey {
        case en
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        let titleContainer = try attributes.nestedContainer(keyedBy: TitleCodingKeys.self, forKey: .title)
        self.title = try titleContainer.decode(String.self, forKey: .en)
        
        let descriptionContainer = try attributes.nestedContainer(keyedBy: DescriptionCodingKeys.self, forKey: .description)
        self.description = try descriptionContainer.decode(String.self, forKey: .en)
        
        let tagsContainer = try attributes.decode([TagFromManga].self, forKey: .tags)
        
        var arr: [String] = []
        for tag in tagsContainer {
            arr.append(tag.name)
        }
        self.tags = arr
        
        let relationshipsContainer = try container.decode([MDRelationship].self, forKey: .relationships)
        
        var artistArr: [String] = []
        artistArr.append("Author Name")
        for relation in relationshipsContainer {
            if ( relation.type == "author" || relation.type == "artist" ) {
                artistArr.append(relation.id)
            }
        }
        self.artist = artistArr
        
        //The API doesn't provide these.
        self.coverURL = ""
        self.rating = Rating(bayesian: 0, users: 0)
    }
    
    //MARK: - Tag struct collected from the manga request
    struct TagFromManga: Decodable {
        let id: String
        let name: String
        
        enum CodingKeys: String, CodingKey {
            case id, attributes
        }
        
        enum AttributesCodingKeys: String, CodingKey {
            case name
        }
        
        enum NameCodingKeys: String, CodingKey {
            case en
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.id = try container.decode(String.self, forKey: .id)
            
            let attributes = try container.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
            let nameContainer = try attributes.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
            self.name = try nameContainer.decode(String.self, forKey: .en)
        }
    }
}

struct MDRelationship: Decodable {
    let id: String
    let type: String
}

struct ReturnedMangas: Decodable {
    let results: [ReturnedManga]
}

//MARK: - Manga returned from seach struct 
struct ReturnedManga: Decodable, Hashable {
    let title: String
    let coverArtURL: String
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    enum DataCodingKeys: String, CodingKey {
        case id, attributes
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case title
    }
    
    enum TitleCodingKeys: String, CodingKey {
        case en
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        self.id = try data.decode(String.self, forKey: .id)
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        let titleContainer = try attributes.nestedContainer(keyedBy: TitleCodingKeys.self, forKey: .title)
        self.title = try titleContainer.decode(String.self, forKey: .en)
        
        self.coverArtURL = ""
    }
    
    init(title: String, coverArtURL: String, id: String) {
        self.title = title
        self.coverArtURL = coverArtURL
        self.id = id
    }
}
