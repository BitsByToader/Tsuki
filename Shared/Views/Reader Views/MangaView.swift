//
//  MangaView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 27/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct MangaView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var appState: AppState
    
    @State var manga: Manga = Manga(title: "", artist: "", coverURL: "", description: "", rating: Manga.Rating(bayesian: "", users: ""), tags: [])
    
    @State var chapters: [Chapter] = [] //chapters -- remoteChapters
    @State var localChapters: [DownloadedChapter] = []
    
    @State var reloadContents: Bool
    
    @State private var descriptionExpanded: Bool = false
    @State private var chapterDownloadingViewPresented: Bool = false
    @State private var presentAlert: Bool = false
    
    var mangaId: String
    
    enum MangaStatus: String, CaseIterable {
        case unfollow = "Unfollow"
        case reading = "Reading"
        case completed = "Completed"
        case onHold = "On Hold"
        case planning = "Plan to read"
        case dropped = "Dropped"
        case reReading = "Re-Reading"
    }
    
    var body: some View {
        List {
            //MARK: - Header
            MangaViewTitle(manga: manga)
            //MARK: - Manga actions
            HStack {
                Spacer()
                
                VStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                    Text("Status")
                        .contextMenu {
                            ForEach(Array(MangaStatus.allCases.enumerated()), id: \.offset) { index, status in
                                Button(action: {
                                    if ( status == .unfollow ) {
                                        updateMangaStatus(statusId: Int(mangaId)! )
                                    } else {
                                        updateMangaStatus(statusId: index)
                                    }
                                }) {
                                    Text("\(status.rawValue)")
                                }
                            }
                        }
                }
                .padding(5)
                .hoverEffect(.automatic)
                .foregroundColor(Color(.systemBlue))
                
                Divider()
                
                VStack(spacing: 3) {
                    Image(systemName: "play.fill")
                    Text("Resume")
                }.padding(15)
                .hoverEffect(.automatic)
                .foregroundColor(Color(.systemBlue))
                .alert(isPresented: $presentAlert) {
                    Alert(title: Text("Coming soon...™️"), message: Text("This feature is currently unavailable. It will be coming soon in an update, so hang tight!"), dismissButton: Alert.Button.cancel(Text("OK")))
                }
                .onTapGesture {
                    self.presentAlert = true
                }
                
                Divider()
                
                VStack(spacing: 3) {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Download")
                }.padding(5)
                .hoverEffect(.automatic)
                .foregroundColor(Color(.systemBlue))
                .onTapGesture {
                    chapterDownloadingViewPresented = true
                }.sheet(isPresented: $chapterDownloadingViewPresented) {
                    ChapterSelectionView(isPresented: $chapterDownloadingViewPresented,manga: manga, chapters: chapters.reversed(), selectedChapters: [Bool](repeating: false, count: chapters.count))
                        .environment(\.managedObjectContext, moc)
                }
                
                Spacer()
            }
            //MARK: - Description
            VStack(alignment: .leading) {
                Text("Description")
                    .font(.title2)
                    .bold()
                
                Text(manga.description)
                    .padding(.top, 5)
            }.frame(maxHeight: descriptionExpanded ? .infinity : 200)
            .onTapGesture {
                descriptionExpanded.toggle()
            }
            //MARK: - Tags
            VStack(alignment: .leading) {
                Text("Genres")
                    .font(.title2)
                    .bold()
                
                MangaViewTags(tagsToDisplay: manga.tags)
            }
            //MARK: - Chapters
            VStack(alignment: .leading, spacing: 10) {
                Text("Chapters")
                    .font(.title2)
                    .bold()
                
                if chapters.isEmpty && localChapters.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("No chapters available")
                            .font(.title3)
                            .bold()
                            .foregroundColor(Color(.lightGray))
                            .frame(height: 200)
                        Spacer()
                    }
                    Spacer()
                } else {
                    if localChapters.isEmpty {
                        MangaViewChapterList(chapters: chapters, remote: true)
                    } else {
                        MangaViewChapterList(chapters: [], remote: false, localChapters: localChapters)
                    }
                }
            }
        }.onAppear{
            if reloadContents {
                appState.isLoading = true
                loadMangaInfo()
                self.reloadContents = false
            }
        }.navigationTitle(mangaId != "" ? manga.title : "Please select a manga to read")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(PlainListStyle())
    }
    
    //MARK: - Manga details loader
    func loadMangaInfo() {
        guard let url = URL(string: "https://mangadex.org/api/manga/\(mangaId)") else {
            print("From MangaView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(MangaDataModel.self, from: data)
                    
                    var filteredChapters: [Chapter] = []
                    
                    for chapter in decodedResponse.chapters {
                        if ( chapter.chapterInfo.langCode == "gb" ) {
                            filteredChapters.append(chapter)
                        }
                    }
                    
                    //Sort the array based on the chapter...
                    //Would've liked to also sort based on volume as well (like when a
                    //chapter's number gets reset with the volume, like how it is in actual books
                    //But mangas that don't have a volume number, will get their sort all messed up
                    //And will leave the chapters without a volume last (even though they might be first)
                    
                    filteredChapters = filteredChapters.sorted {
                        return Double($0.chapterInfo.chapter)! > Double($1.chapterInfo.chapter)!
                    }
                    
                    DispatchQueue.main.async {
                        self.manga = decodedResponse.manga
                        self.manga.coverURL = "https://mangadex.org" + decodedResponse.manga.coverURL
                        self.chapters = filteredChapters
                        appState.isLoading = false
                    }
                    
                    return
                } catch {
                    DispatchQueue.main.async {
                        appState.errorMessage += "An error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.isLoading = false
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.isLoading = false
                    }
                }
            }
        }.resume()
    }
    //MARK: - Update the reading status of the manga
    func updateMangaStatus(statusId: Int) {
        appState.isLoading = true
        
        var action: String = ""
        if ( statusId == Int(mangaId)! ) {
            action = "manga_unfollow"
        } else {
            action = "manga_follow"
        }
        
        guard let url = URL(string :"https://mangadex.org/ajax/actions.ajax.php?function=\(action)&id=\(mangaId)&type=\(statusId)&_=\(Int(Date().timeIntervalSince1970))") else {
            print("from updateMangaStatus: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                print(String(bytes: data, encoding: .utf8))
                DispatchQueue.main.async {
                    withAnimation {
                        appState.isLoading = false
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                withAnimation {
                    appState.errorOccured = true
                    appState.isLoading = false
                }
            }
        }.resume()
    }
}

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        MangaView(reloadContents: false, mangaId: "1")
    }
}
