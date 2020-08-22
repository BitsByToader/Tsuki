//
//  Tag.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 24/07/2020.
//

import Foundation

struct Tag: Hashable {
    let tagName: String
    let id: String
}

struct TagSection: Hashable {
    let tags: [Tag]
    let sectionName: String
}
