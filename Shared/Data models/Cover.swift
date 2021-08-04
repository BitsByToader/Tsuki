//
//  Cover.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 13.06.2021.
//

import Foundation

struct Cover: Decodable {
    let path: String
    let mangaId: String
    
    enum CodingKeys: String, CodingKey {
        case data, relationships
    }
    
    enum DataCodingKeys: String, CodingKey {
        case attributes
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case fileName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
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

struct Covers: Decodable {
    let results: [Cover]
}
