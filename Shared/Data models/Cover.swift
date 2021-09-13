//
//  Cover.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 13.06.2021.
//

import Foundation

struct CoverEntity: Decodable {
    let path: String
    let mangaId: String
    
    enum CodingKeys: String, CodingKey {
        case attributes, relationships
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case fileName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let attributes = try container.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        let fileName = try attributes.decode(String.self, forKey: .fileName)
        
        let relationships = try container.decode([MDRelationship].self, forKey: .relationships)
        
        var mangaId: String = ""
        for relation in relationships {
            if ( relation.type == "manga" ) {
                mangaId = relation.id
                break
            }
        }
        
        self.mangaId = mangaId
        self.path = "https://uploads.mangadex.org/covers/\(mangaId)/\(fileName).256.jpg"
    }
}

struct Cover: Decodable {
    let path: String
    let mangaId: String
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let entity = try container.decode(CoverEntity.self, forKey: .data)
        
        self.path = entity.path
        self.mangaId = entity.mangaId
    }
    
    init(path: String, mangaId: String) {
        self.path = path
        self.mangaId = mangaId
    }
}

struct Covers: Decodable {
    let data: [CoverEntity]
}
