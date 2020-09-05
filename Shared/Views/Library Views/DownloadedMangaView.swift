//
//  DownloadedMangaView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/08/2020.
//

import SwiftUI

struct DownloadedMangaView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DownloadedManga.entity(), sortDescriptors: []) var downloadedMangas: FetchedResults<DownloadedManga>
    
    var body: some View {
        VStack {
            List {
                ForEach(Array(downloadedMangas.enumerated()), id: \.offset) { index, manga in
                    NavigationLink(destination: MangaView(manga: Manga(fromDownloadedManga: manga), localChapters: manga.chapterArray, reloadContents: false, mangaId: "")) {
                        DownloadedMangaListRow(manga: manga)
                    }
                }.onDelete(perform: deleteManga)
                
                
            }
        }.navigationTitle(Text("Downloaded manga"))
        .navigationBarTitleDisplayMode(.large)
    }
    
    func deleteManga(at offsets: IndexSet) {
        withAnimation {
            self.moc.delete(downloadedMangas[offsets.first ?? 0])
            try? self.moc.save()
        }
    }
}

struct DownloadedMangaView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadedMangaView()
    }
}
