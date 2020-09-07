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
    
    @State private var mangaToDelete: IndexSet = IndexSet()
    @State private var deleteWarningPresented: Bool = false
    
    var body: some View {
        VStack {
            if !downloadedMangas.isEmpty {
                List {
                    ForEach(Array(downloadedMangas.enumerated()), id: \.offset) { index, manga in
                        NavigationLink(destination: MangaView(manga: Manga(fromDownloadedManga: manga), localChapters: manga.chapterArray, reloadContents: false, mangaId: "")) {
                            DownloadedMangaListRow(manga: manga)
                        }
                    }.onDelete(perform: askForPermission)
                }.actionSheet(isPresented: $deleteWarningPresented) {
                    ActionSheet(
                        title: Text("Wait a second!"),
                        message: Text("This action will delete this downloaded manga, as well as *ALL* chapters associated with it... This action is non-reversable. Are you sure you want to continue?"),
                        buttons: [
                            .cancel(Text("Cancel"), action: {deleteWarningPresented = false}),
                            .destructive(Text("Delete"), action: {deleteManga(at: mangaToDelete)})
                        ]
                    )
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
    
    func askForPermission(at offsets: IndexSet) {
        mangaToDelete = offsets
        deleteWarningPresented.toggle()
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
