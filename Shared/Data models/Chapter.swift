//
//  Chapter.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 29/07/2020.
//

import Foundation

struct Chapter: Decodable, Hashable {
    let mangaId: String
    let chapterId: String
    let hash: String
    
    let volume: String
    let chapter: String
    let title: String
    
    let dataPages: [String]
    let dataSaverPages: [String]
    
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case data, relationships
    }
    
    enum DataCodingKeys: String, CodingKey {
        case id, attributes
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case title, volume, chapter, hash, data, dataSaver, publishAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        
        self.chapterId = try data.decode(String.self, forKey: .id)
        
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        self.title = ( try? attributes.decode(String.self, forKey: .title) ) ?? ""
        self.hash = try attributes.decode(String.self, forKey: .hash)
        
        self.volume = ( try? attributes.decode(String.self, forKey: .volume) ) ?? "1"
        self.chapter = try attributes.decode(String.self, forKey: .chapter)
        
        self.dataPages = try attributes.decode([String].self, forKey: .data)
        self.dataSaverPages = try attributes.decode([String].self, forKey: .dataSaver)
        
        self.timestamp = try attributes.decode(String.self, forKey: .publishAt)
        
        let relationships = try container.decode([MDRelationship].self, forKey: .relationships)
        
        var manga = ""
        for relationship in relationships {
            if ( relationship.type == "manga" ) {
                manga = relationship.id
                break
            }
        }
        self.mangaId = manga
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
