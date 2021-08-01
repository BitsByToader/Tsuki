//
//  MangaViewTitle.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 25/08/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct MangaViewTitle: View {
    @Binding var authorDetailsPresented: Bool
    let manga: Manga
    
    var body: some View {
        HStack(alignment: .top) {
            WebImage(url: URL(string: manga.coverURL))
                .resizable()
                .placeholder {
                    Rectangle().foregroundColor(.gray)
                        .opacity(0.2)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFit()
                .frame(width: 100)
                .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Text(manga.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                
                Button {
                    authorDetailsPresented = true
                } label: {
                    Text(manga.artist[0])
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(Color(.gray))
                }
                
                Spacer()
                
                HStack {
                    ForEach((1..<6)) { index in
                        if Float(index * 2) <= manga.rating.bayesian {
                            Image(systemName: "star.fill")
                        } else if Float(index * 2) - 1  <= manga.rating.bayesian {
                            Image(systemName: "star.lefthalf.fill")
                        } else {
                            Image(systemName: "star")
                        }
                    }
                    
                    Text(String(format: "%.2f", manga.rating.bayesian))
                        .foregroundColor(Color(.gray))
                }
                
                Text("\(manga.rating.users) ratings")
                    .foregroundColor(Color(.gray))
                
                Spacer()
            }
        }
    }
}
