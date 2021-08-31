//
//  Author.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 14.05.2021.
//

import Foundation

struct Author: Decodable {
    let id: String
    let name: String
    let imageUrl: String
    let biography: String
    let mangaIdsFromAuthor: [String]
    
    init() {
        id = ""
        name = ""
        imageUrl = ""
        biography = ""
        mangaIdsFromAuthor = []
    }
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    enum DataCodingKeys: String, CodingKey {
        case attributes, id, relationships
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case name, imageUrl, biography
    }
    
    enum BiographyCodingKeys: String, CodingKey {
        case property1
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        self.id = try data.decode(String.self, forKey: .id)
        self.name = try attributes.decode(String.self, forKey: .name)
        self.imageUrl = ( try? attributes.decode(String.self, forKey: .imageUrl) ) ?? ""
        
        self.biography = ""
        
        let relationships = try data.decode([MDRelationship].self, forKey: .relationships)
        var arr: [String] = []
        for relation in relationships {
            if ( relation.type == "manga" ) {
                arr.append(relation.id)
            }
        }
        
        self.mangaIdsFromAuthor = arr
    }
}
