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
            if !downloadedMangas.isEmpty {
                List {
                    ForEach(Array(downloadedMangas.enumerated()), id: \.offset) { index, manga in
                        NavigationLink(destination: MangaView(manga: Manga(fromDownloadedManga: manga), localChapters: manga.chapterArray, reloadContents: false, mangaId: "")) {
                            DownloadedMangaListRow(manga: manga)
                        }
                    }.onDelete(perform: deleteManga)
                }
            } else {
                Text("You have no downloaded mangas")
                    .font(.title3)
                    .bold()
                    .foregroundColor(Color(.lightGray))
            }
        }.navigationTitle(Text("Downloaded manga"))
        .navigationBarTitleDisplayMode(.large)
    }
    
    func deleteManga(at offsets: IndexSet) {
        withAnimation {
            let index = offsets.first ?? 0
            let fileManager = FileManager.default
            let docPath = getDocumentsDirectory()
            for chapter in downloadedMangas[index].chapterArray {
                for page in chapter.wrappedPages {
                    do {
                        try fileManager.removeItem(at: docPath.appendingPathComponent(page))
                    } catch {
                        print(error)
                    }
                    print("Deleted image: \(page)")
                }
            }
            
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
