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
    
    let volume: String
    let chapter: String
    let title: String
    
    let timestamp: String
    let chapterLanguageCode: String
    
    var isRead: Bool = false
    
    //MARK: - Conforms to Decoder
    enum CodingKeys: String, CodingKey {
        case id, attributes, relationships
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case title, volume, chapter, hash, data, dataSaver, publishAt, translatedLanguage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.chapterId = try container.decode(String.self, forKey: .id)
        
        let attributes = try container.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        self.title = ( try? attributes.decode(String.self, forKey: .title) ) ?? ""
        
        self.volume = ( try? attributes.decode(String.self, forKey: .volume) ) ?? "1"
        self.chapter = ( try? attributes.decode(String.self, forKey: .chapter) ) ?? "1"
        
        self.timestamp = try attributes.decode(String.self, forKey: .publishAt)
        self.chapterLanguageCode = try attributes.decode(String.self, forKey: .translatedLanguage)
        
        let relationships = try container.decode([MDRelationship].self, forKey: .relationships)
        
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
