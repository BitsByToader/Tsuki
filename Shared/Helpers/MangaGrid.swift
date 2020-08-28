//
//  MangaGrid.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 06/08/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct MangaGrid: View {
    var dataSource: [ReturnedManga]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
            ForEach(dataSource, id: \.self) { manga in
                NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.id)) {
                    PlainManga(manga: manga)
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct PlainManga: View {
    var manga: ReturnedManga
    
    var body: some View {
        VStack {
            WebImage(url: URL(string: manga.coverArtURL))
                .resizable()
                .placeholder {
                    Rectangle().foregroundColor(.gray)
                        .opacity(0.2)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFit()
                .frame(height: 180)
            
            Text(manga.title)
                .multilineTextAlignment(.center)
            
            Spacer()
        }.frame(height: 250)
    }
}

//struct MangaGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        MangaGrid()
//    }
//}
