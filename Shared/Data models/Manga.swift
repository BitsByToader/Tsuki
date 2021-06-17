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
    var artistId: [String]
    var coverURL: String
    let description: String
    let rating: Rating
    let tags: [String]
    
    init() {
        self.title = ""
        self.artist = [""]
        self.artistId = [""]
        self.coverURL = ""
        self.description = ""
        self.rating = Rating(bayesian: 1, users: 0)
        self.tags = []
    }
    
    init( title: String, artist: String, coverURL: String, description: String, rating: Rating, tags: [String]) {
        self.title = title
        self.artist = [artist]
        self.artistId = []
        self.coverURL = coverURL
        self.description = description
        self.rating = rating
        self.tags = tags
    }
    
    init(fromDownloadedManga manga: DownloadedManga) {
        title = manga.wrappedMangaTitle
        artist = [manga.wrappedMangaArtist]
        artistId = []
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
        case id, attributes
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
        let id: String = try data.decode(String.self, forKey: .id)
        
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
        var artistIdArr: [String] = []
        var cover: String = ""
        
        for relation in relationshipsContainer {
            if ( relation.type == "author" || relation.type == "artist" ) {
                artistArr.append(relation.authorName)
                artistIdArr.append(relation.id)
            } else if ( relation.type == "cover_art" ) {
                cover = relation.coverFileName
            }
        }
        
        self.artist = artistArr
        self.artistId = artistIdArr
        self.coverURL = "https://uploads.mangadex.org/covers/\(id)/\(cover).256.jpg"
        
        //The API doesn't provide these yet...
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
//MARK: - MDRelationship
struct MDRelationship: Decodable {
    let id: String
    let type: String
    
    //Optional values that can be decoded from the attributes of a relationship
    let coverFileName: String
    let authorName: String
    let mangaTitle: String
    
    enum CodingKeys: String, CodingKey {
        case id, type, attributes
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case fileName, name, title
    }
    
    enum MangaNameCodingKeys: String, CodingKey {
        case en
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(String.self, forKey: .type)
        
        let attributesContainer = try? container.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        self.coverFileName = ( try? attributesContainer?.decode(String.self, forKey: .fileName) ) ?? ""
        self.authorName = ( try? attributesContainer?.decode(String.self, forKey: .name) ) ?? ""
        
        let mangaNamesContainer = try? attributesContainer?.nestedContainer(keyedBy: MangaNameCodingKeys.self, forKey: .title)
        self.mangaTitle = ( try? mangaNamesContainer?.decode(String.self, forKey: .en) ) ?? ""
    }
}
//MARK: - Manga returned from seach struct 
struct ReturnedMangas: Decodable {
    let results: [ReturnedManga]
}

struct ReturnedManga: Decodable, Hashable {
    let title: String
    var coverArtURL: String
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case data, relationships
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
    
    init() {
        self.coverArtURL = ""
        self.id = ""
        self.title = ""
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        self.id = try data.decode(String.self, forKey: .id)
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        let titleContainer = try attributes.nestedContainer(keyedBy: TitleCodingKeys.self, forKey: .title)
        self.title = try titleContainer.decode(String.self, forKey: .en)
        
        let relationships = try container.decode([MDRelationship].self, forKey: .relationships)
        
        var coverName: String = ""
        for relation in relationships {
            if ( relation.type == "cover_art" ) {
                coverName = relation.coverFileName
                break
            }
        }
        
        #warning("Make this URL user changeable as well.")
        self.coverArtURL = "https://uploads.mangadex.org/covers/\(self.id)/\(coverName).256.jpg"
    }
    
    init(title: String, coverArtURL: String, id: String) {
        self.title = title
        self.coverArtURL = coverArtURL
        self.id = id
    }
}
