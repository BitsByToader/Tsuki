//
//  DownloadedMangaListRow.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/08/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct DownloadedMangaListRow: View {
    var manga: DownloadedManga
    
    var body: some View {
        HStack {
            WebImage(url: URL(string: manga.wrappedMangaCoverURL))
                .resizable()
                .placeholder {
                    Rectangle().foregroundColor(.gray)
                        .opacity(0.2)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFit()
                .frame(height: 100)
                .cornerRadius(5)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(manga.wrappedMangaTitle)
                    .font(.title2)
                    .bold()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(manga.wrappedMangaArtist)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(Color(.gray))
                
                Text("Chapters downloaded: \(manga.chapterArray.count)")
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(Color(.gray))
            }
        }
    }
}
