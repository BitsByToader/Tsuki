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
    
    let reachedTheBottom: () -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
            if dataSource.isEmpty {
                ForEach(0..<12) { _ in
                    PlaceholderManga()
                }
            }
            ForEach(Array(dataSource.enumerated()), id: \.element.id) { (index, manga) in
                NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.id)) {
                    PlainManga(manga: manga)
                        .onAppear {
                            if index + 1 == dataSource.count {
                                print("Reached the bottom")
                                
                                reachedTheBottom()
                            }
                        }
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
                .cornerRadius(8)
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
