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
            WebImage(url: URL(string: manga.mangaCoverURL ?? ""))
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
                Text(manga.mangaTitle ?? "")
                    .font(.title2)
                    .bold()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(manga.mangaArtist ?? "")
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(Color(.gray))
                
                Text("Downloaded chapter 2 to 69")
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(Color(.gray))
            }
        }
    }
}
