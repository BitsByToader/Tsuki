//
//  ChapterSelectionView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/08/2020.
//

import SwiftUI

struct ChapterSelectionView: View {
    @Environment(\.managedObjectContext) var moc
    
    @Binding var isPresented: Bool
    var manga: Manga
    var chapters: [Chapter]
    
    var body: some View {
        VStack {
            Spacer()
            Text("Select chapters")
                .bold()
                .font(.largeTitle)
            Spacer()
            VStack(alignment: .leading, spacing: 5) {
                Text("Select chapters inbetween")
                
                List(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                    Text("Vol.\(chapter.chapterInfo.volume ?? "") Ch.\(chapter.chapterInfo.chapter ?? "")")
                }.listStyle(InsetListStyle())
                .frame(maxHeight: 400)
            }
            Spacer()
            
            Button(action: {
                let mangaToDownload = DownloadedManga(context: moc)
                
                mangaToDownload.mangaArtist = manga.artist
                mangaToDownload.mangaCoverURL = manga.coverURL
                mangaToDownload.mangaId = UUID()
                mangaToDownload.mangaTitle = manga.title
                mangaToDownload.mangaRating = manga.rating.bayesian
                mangaToDownload.mangaTags = manga.tags
                mangaToDownload.mangaDescription = manga.description
                mangaToDownload.usersRated = manga.rating.users
                
                try? self.moc.save()
                
                self.isPresented = false
            }) {
                Text("Download Chapters")
                    .bold()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
}

//struct ChapterSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChapterSelectionView()
//    }
//}
