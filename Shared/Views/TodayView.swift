//
//  TodayView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 26/08/2020.
//

import SwiftUI

struct TodayView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var appState: AppState
    @State private var loadingMangas: Bool = true
    
//    @State private var newChapters: [] = []
    @State private var featuredDisplayedMangas: [ReturnedManga] = []
    @State private var newDisplayedMangas: [ReturnedManga] = []
    
    var body: some View {
        NavigationView {
            List {
                //MARK: -Latest Updates
                VStack(alignment: .leading) {
                    Text("Newest chapters")
                        .font(.title2)
                        .bold()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            if loadingMangas {
                                ForEach(0..<6) {_ in
                                    PlaceholderManga()
                                }
                            } else {
                                /*ForEach(newChapters, id: \.self) { manga in
                                    NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.id)) {
                                        UpdatedManga(manga: manga)
                                    }.buttonStyle(PlainButtonStyle())
                                    .frame(width: 125)
                                }*/
                            }
                        }
                    }
                }
                //MARK: - Featured Manga
                VStack(alignment: .leading) {
                    Text("Featured Manga")
                        .font(.title2)
                        .bold()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            if loadingMangas {
                                ForEach(0..<6) {_ in
                                    PlaceholderManga()
                                }
                            } else {
                                ForEach(featuredDisplayedMangas, id: \.self) { manga in
                                    NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.id)) {
                                        PlainManga(manga: manga)
                                    }.buttonStyle(PlainButtonStyle())
                                    .frame(width: 125)
                                }
                            }
                        }
                    }
                }
                //MARK: - New Manga
                VStack(alignment: .leading) {
                    Text("New Titles")
                        .font(.title2)
                        .bold()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            if loadingMangas {
                                ForEach(0..<6) {_ in
                                    PlaceholderManga()
                                }
                            } else {
                                ForEach(newDisplayedMangas, id: \.self) { manga in
                                    NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.id)) {
                                        PlainManga(manga: manga)
                                    }.buttonStyle(PlainButtonStyle())
                                    .frame(width: 125)
                                }}
                        }
                    }
                }
            }.listStyle(PlainListStyle())
            .navigationTitle(Text("Today"))
            
            MangaView(reloadContents: !featuredDisplayedMangas.isEmpty, mangaId: featuredDisplayedMangas.isEmpty ? "" : featuredDisplayedMangas[0].id)

            ChapterView(loadContents: false, isViewPresented: .constant(1), remainingChapters: [])
            
        }.if( sizeClass == .regular ) { $0.navigationViewStyle(DoubleColumnNavigationViewStyle()) }
        .if( sizeClass == .compact ) { $0.navigationViewStyle(StackNavigationViewStyle()) }
        .onAppear {
            //loadUpdates()
        }
    }
    
    func loadUpdates() {
        let loadingDescription: LocalizedStringKey = "Loading mangas..."
        
        appState.loadingQueue.append(loadingDescription)
        self.loadingMangas = true
        
        guard let url = URL(string: "https://mangadex.org") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From TodayView: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    
//                    let doc: Document = try SwiftSoup.parse(String(data: data, encoding: .utf8)!)
//
//                    //MARK: - Retrieve latest updated manga
//                    let latestUpdatedChapters = try doc.getElementById("latest_update")?.child(0).children().array()
//                    var latestUpdatedMangas: [ReturnedUpdatedManga] = []
//                    for manga in latestUpdatedChapters ?? [] {
//                        let title: String = try manga.child(1).getElementsByClass("manga_title").first()!.text()
//
//                        let mangaLink: String = try manga.child(1).getElementsByClass("manga_title").first()!.attr("href")
//                        let mangaId: String = mangaLink.components(separatedBy: "/")[2]
//
//                        let coverArt: String = try manga.getElementsByClass("sm_md_logo").first()!.select("a").select("img").attr("src")
//
//                        let timeOfUpdate: String = try manga.children().array()[2].select("a").text()
//                        let chapter: String = try manga.children().array()[4].text()
//
//                        latestUpdatedMangas.append(ReturnedUpdatedManga(title: title, coverArtURL: coverArt, id: mangaId, timeOfUpdate: timeOfUpdate, volumeAndChapter: chapter))
//                    }
//
//                    //MARK: - Retrieve featured titles
//                    let featuredTitles = try doc.getElementById("hled_titles_owl_carousel")?.children().array()
//                    var featuredMangas: [ReturnedManga] = []
//                    for manga in featuredTitles ?? [] {
//                        let result: ReturnedManga =  try extractMangaFromCarousel(element: manga)
//
//                        featuredMangas.append(result)
//                    }
//
//                    //MARK: - Retrieve featured titles
//                    let newTitles = try doc.getElementById("new_titles_owl_carousel")?.children().array()
//                    var newMangas: [ReturnedManga] = []
//                    for manga in newTitles ?? [] {
//                        let result: ReturnedManga =  try extractMangaFromCarousel(element: manga)
//
//                        newMangas.append(result)
//                    }
//
//                    //MARK: - Update View
//                    DispatchQueue.main.async {
//                        self.newChapters = latestUpdatedMangas
//                        self.featuredDisplayedMangas = featuredMangas
//                        self.newDisplayedMangas = newMangas
//                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
//                        self.loadingMangas = false
//                    }
                    //MARK: -
                    return
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Unknown error when parsing response from server.\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                withAnimation {
                    appState.errorOccured = true
                    appState.removeFromLoadingQueue(loadingState: loadingDescription)
                }
            }
            return
        }.resume()
    }
    
//    func extractMangaFromCarousel(element: Element) throws -> ReturnedManga {
//        let mangaTitle: Element = try element.child(1)
//            .select("p").first()!.getElementsByClass("manga_title").first()!
//        
//        let _: String = try mangaTitle.text()
//
//        let mangaLink: String = try mangaTitle.attr("href")
//        let _: String = mangaLink.components(separatedBy: "/")[2]
//
//        let _: String = try element.child(0).select("a").select("img").attr("data-src")
//
//        return ReturnedManga(title: "title", coverArtURL: "coverArt", id: "mangaId")
//    }
}

extension View {
  @ViewBuilder
  func `if`<Transform: View>(
    _ condition: Bool,
    transform: (Self) -> Transform
  ) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}


//struct TodayView_Previews: PreviewProvider {
//    static var previews: some View {
//        TodayView()
//    }
//}
