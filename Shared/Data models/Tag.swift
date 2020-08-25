//
//  Tag.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 24/07/2020.
//

import Foundation
import SwiftUI

class MangaTags: ObservableObject  {
    var tags: [Tag] = []
}

struct Tag: Hashable {
    let tagName: String
    let id: String
}

struct TagSection: Hashable {
    let tags: [Tag]
    let sectionName: String
}
