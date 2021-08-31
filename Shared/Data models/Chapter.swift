//
//  Chapter.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 29/07/2020.
//

import Foundation

struct Chapter: Decodable, Hashable {
    //MARK: - Properties
    let mangaId: String
    let mangaTitle: String
    
    let chapterId: String
    let hash: String
    
    let volume: String
    let chapter: String
    let title: String
    
    let dataPages: [String]
    let dataSaverPages: [String]
    
    let timestamp: String
    let chapterLanguageCode: String
    
    var isRead: Bool = false
    
    //MARK: - Conforms to Decoder
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    enum DataCodingKeys: String, CodingKey {
        case id, attributes, relationships
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case title, volume, chapter, hash, data, dataSaver, publishAt, translatedLanguage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        
        self.chapterId = try data.decode(String.self, forKey: .id)
        
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        self.title = ( try? attributes.decode(String.self, forKey: .title) ) ?? ""
        self.hash = try attributes.decode(String.self, forKey: .hash)
        
        self.volume = ( try? attributes.decode(String.self, forKey: .volume) ) ?? "1"
        self.chapter = ( try? attributes.decode(String.self, forKey: .chapter) ) ?? "1"
        
        self.dataPages = ( try? attributes.decode([String].self, forKey: .data) ) ?? []
        self.dataSaverPages = ( try? attributes.decode([String].self, forKey: .dataSaver) ) ?? []
        
        self.timestamp = try attributes.decode(String.self, forKey: .publishAt)
        self.chapterLanguageCode = try attributes.decode(String.self, forKey: .translatedLanguage)
        
        let relationships = try data.decode([MDRelationship].self, forKey: .relationships)
        
        var mangaId = ""
        var mangaName = ""
        for relationship in relationships {
            if ( relationship.type == "manga" ) {
                mangaId = relationship.id
                mangaName = relationship.mangaTitle
                break
            }
        }
        
        self.mangaId = mangaId
        self.mangaTitle = mangaName
    }
}

//MARK: - PageData struct
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
