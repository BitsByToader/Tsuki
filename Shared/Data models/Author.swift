//
//  Author.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 14.05.2021.
//

import Foundation

struct Author: Decodable {
    let authorName: String
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    enum DataCodingKeys: String, CodingKey {
        case attributes
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        self.authorName = try attributes.decode(String.self, forKey: .name)
    }
}
