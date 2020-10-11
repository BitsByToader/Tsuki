//
//  MangaViewTags.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 25/08/2020.
//

import SwiftUI

struct MangaViewTags: View {
    @EnvironmentObject var mangaTags: MangaTags
    let tagsToDisplay: [Int]
    
    var tags: [String] {
        var array: [String] = []
        
        let tagsToUse: [Tag] = mangaTags.tags.isEmpty ? DefaultTags().tags : mangaTags.tags
        
        for tag in tagsToDisplay {
            for index in 0..<tagsToUse.count {
                if ( "\(tag)" == tagsToUse[index].id ) {
                    array.append(tagsToUse[index].tagName)
                    break
                }
            }
        }
        
        return array
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack{
                ForEach(tags, id: \.self) { tag in
                    Text("\(tag)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray))
                        .frame(width: 65, height: 65)
                    
                    Divider()
                }
            }
        }
    }
}

//struct MangaViewTags_Previews: PreviewProvider {
//    static var previews: some View {
//        MangaViewTags([1,50,48,70,89])
//    }
//}
