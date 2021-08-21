//
//  MangaViewTags.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 25/08/2020.
//

import SwiftUI

struct MangaViewTags: View {
    @EnvironmentObject var mangaTags: MangaTags
    let tagsToDisplay: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack{
                ForEach(tagsToDisplay, id: \.self) { tag in
                    Text("\(tag)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray))
                        .frame(minWidth: 65, minHeight: 65, maxHeight: 65)
                    
                    Divider()
                }
            }
        }
    }
}
