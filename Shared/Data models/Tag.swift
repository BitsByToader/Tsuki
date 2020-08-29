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
    var state: ToggleState = .untoggled
    
    enum ToggleState {
        case enabled
        case disabled
        case untoggled
    }
}

struct TagSection: Hashable {
    var tags: [Tag]
    let sectionName: String
}
