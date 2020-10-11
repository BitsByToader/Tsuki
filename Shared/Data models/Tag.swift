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

struct DefaultTags {
    var tags: [Tag] = [
        Tag(tagName: "Ecchi", id: "9"),
        Tag(tagName: "Gore", id: "49"),
        Tag(tagName: "Sexual Violence", id: "50"),
        Tag(tagName: "Smut", id: "32"),
        Tag(tagName: "4-Koma", id: "1"),
        Tag(tagName: "Adaptation", id: "42"),
        Tag(tagName: "Anthology", id: "43"),
        Tag(tagName: "Award Winning", id: "4"),
        Tag(tagName: "Doujinshi", id: "7"),
        Tag(tagName: "Fan Colored", id: "48"),
        Tag(tagName: "Full Color", id: "45"),
        Tag(tagName: "Long Strip", id: "36"),
        Tag(tagName: "Official Colored", id: "47"),
        Tag(tagName: "Oneshot", id: "21"),
        Tag(tagName: "User Created", id: "46"),
        Tag(tagName: "Web Comic", id: "44"),
        Tag(tagName: "Action", id: "2"),
        Tag(tagName: "Adventure", id: "3"),
        Tag(tagName: "Comedy", id: "5"),
        Tag(tagName: "Crime", id: "51"),
        Tag(tagName: "Drama", id: "8"),
        Tag(tagName: "Fantasy", id: "10"),
        Tag(tagName: "Historical", id: "13"),
        Tag(tagName: "Horror", id: "14"),
        Tag(tagName: "Isekai", id: "41"),
        Tag(tagName: "Magical Girls", id: "52"),
        Tag(tagName: "Mecha", id: "17"),
        Tag(tagName: "Medical", id: "18"),
        Tag(tagName: "Mystery", id: "20"),
        Tag(tagName: "Philosophical", id: "53"),
        Tag(tagName: "Psychological", id: "22"),
        Tag(tagName: "Romance", id: "23"),
        Tag(tagName: "Sci-Fi", id: "25"),
        Tag(tagName: "Shoujo Ai", id: "28"),
        Tag(tagName: "Shounen Ai", id: "30"),
        Tag(tagName: "Slice of Life", id: "31"),
        Tag(tagName: "Sports", id: "33"),
        Tag(tagName: "Superhero", id: "54"),
        Tag(tagName: "Thriller", id: "55"),
        Tag(tagName: "Tragedy", id: "35"),
        Tag(tagName: "Wuxia", id: "56"),
        Tag(tagName: "Yaoi", id: "37"),
        Tag(tagName: "Yuri", id: "38"),
        Tag(tagName: "Aliens", id: "57"),
        Tag(tagName: "Animals", id: "58"),
        Tag(tagName: "Cooking", id: "6"),
        Tag(tagName: "Crossdressing", id: "59"),
        Tag(tagName: "Delinquents", id: "61"),
        Tag(tagName: "Demons", id: "60"),
        Tag(tagName: "Genderswap", id: "62"),
        Tag(tagName: "Ghosts", id: "63"),
        Tag(tagName: "Gyaru", id: "11"),
        Tag(tagName: "Harem", id: "12"),
        Tag(tagName: "Incest", id: "83"),
        Tag(tagName: "Loli", id: "65"),
        Tag(tagName: "Mafia", id: "84"),
        Tag(tagName: "Magic", id: "66"),
        Tag(tagName: "Martial Arts", id: "16"),
        Tag(tagName: "Military", id: "67"),
        Tag(tagName: "Monster Girls", id: "64"),
        Tag(tagName: "Monsters", id: "68"),
        Tag(tagName: "Music", id: "19"),
        Tag(tagName: "Ninja", id: "69"),
        Tag(tagName: "Office Workers", id: "70"),
        Tag(tagName: "Police", id: "71"),
        Tag(tagName: "Post-Apocalyptic", id: "72"),
        Tag(tagName: "Reincarnation", id: "73"),
        Tag(tagName: "Reverse Harem", id: "74"),
        Tag(tagName: "Samurai", id: "75"),
        Tag(tagName: "School Life", id: "24"),
        Tag(tagName: "Shota", id: "76"),
        Tag(tagName: "Supernatural", id: "34"),
        Tag(tagName: "Survival", id: "77"),
        Tag(tagName: "Time Travel", id: "78"),
        Tag(tagName: "Traditional Games", id: "80"),
        Tag(tagName: "Vampires", id: "79"),
        Tag(tagName: "Video Games", id: "40"),
        Tag(tagName: "Villainess", id: "85"),
        Tag(tagName: "Virtual Reality", id: "81"),
        Tag(tagName: "Zombies", id: "82")
    ]
}
