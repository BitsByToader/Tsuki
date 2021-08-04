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
    
    @State private var newChapters: [Chapter] = []
    @State private var coversByMangaId: [String: String] = [:]
    
    @State private var seasonalDisplayedManga: [ReturnedManga] = []
    @State private var newDisplayedMangas: [ReturnedManga] = []
    
    @State private var newChaptersLoaded: Bool = false
    @State private var seasonalMangaLoaded: Bool = false
    
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
                            if newChapters.isEmpty {
                                ForEach(0..<6) {_ in
                                    PlaceholderManga()
                                }
                            } else {
                                ForEach(newChapters, id: \.self) { manga in
                                    NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.mangaId)) {
                                        UpdatedManga(manga: manga,
                                                     coverArt: coversByMangaId[manga.mangaId] ?? "",
                                                     mangaTitle: manga.mangaTitle)
                                    }.buttonStyle(PlainButtonStyle())
                                    .frame(width: 125)
                                }
                            }
                        }
                    }
                }
                //MARK: - Seasonal Manga
                VStack(alignment: .leading) {
                    Text("Seasonal Manga")
                        .font(.title2)
                        .bold()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            if seasonalDisplayedManga.isEmpty {
                                ForEach(0..<6) {_ in
                                    PlaceholderManga()
                                }
                            } else {
                                ForEach(seasonalDisplayedManga, id: \.self) { manga in
                                    NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.id)) {
                                        PlainManga(manga: ReturnedManga(title: manga.title,
                                                                        coverArtURL: coversByMangaId[manga.id] ?? "",
                                                                        id: manga.id))
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
                            if newDisplayedMangas.isEmpty {
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
            
            MangaView(reloadContents: !seasonalDisplayedManga.isEmpty, mangaId: seasonalDisplayedManga.isEmpty ? "" : seasonalDisplayedManga[0].id)

            ChapterView(loadContents: false, isViewPresented: .constant(1), remainingChapters: [])
            
        }.if( sizeClass == .regular ) { $0.navigationViewStyle(DoubleColumnNavigationViewStyle()) }
        .if( sizeClass == .compact ) { $0.navigationViewStyle(StackNavigationViewStyle()) }
        .onAppear {
            loadSeasonalManga()
            getNewestTitles()
            loadNewestChapters()
        }
    }
    //MARK: - Get "seasonal" manga
    func loadSeasonalManga() {
        let loadingDescription: LocalizedStringKey = "Loading featured manga..."
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")list/a153b4e6-1fcc-4f45-a990-f37f989c0d74?includes[]=manga") else {
            print("Invalid URL")
            return
        }
        
        appState.loadingQueue.append(loadingDescription)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From TodayView(loadFeaturedManga): \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    struct FeaturedManga: Decodable {
                        let relationships: [MDRelationship]
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(FeaturedManga.self, from: data)
                    
                    var arr: [ReturnedManga] = []
                    for relation in decodedResponse.relationships {
                        if relation.type == "manga" {
                            arr.append(ReturnedManga(title: relation.mangaTitle, coverArtURL: relation.coverFileName, id: relation.id))
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.seasonalDisplayedManga = arr
                        self.seasonalMangaLoaded = true
                        
                        if ( newChaptersLoaded ) {
                            loadCovers()
                        }
                        
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        appState.errorMessage += "(From TodayView, featuredManga) Unknown error when parsing response from server.\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
            }
        }.resume()
    }
    //MARK: - Get newest chapters
    func loadNewestChapters() {
        let loadingDescription: LocalizedStringKey = "Loading newest chapters..."
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "20"))
        urlComponents.queryItems?.append(URLQueryItem(name: "order[createdAt]", value: "desc"))
        urlComponents.queryItems?.append(URLQueryItem(name: "includes[]", value: "manga"))
        
        let pickedLanguages = UserDefaults(suiteName: "group.TsukiApp")?.stringArray(forKey: "pickedLanguages") ?? []
        
        for lang in pickedLanguages {
            urlComponents.queryItems?.append(URLQueryItem(name: "translatedLanguage[]", value: lang))
        }
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")chapter?\(urlComponents.percentEncodedQuery ?? "")") else {
            print("Invalid URL")
            return
        }
        
        appState.loadingQueue.append(loadingDescription)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From TodayView(loadNewestChapters): \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    struct Result: Decodable {
                        let results: [Chapter]
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(Result.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.newChapters = decodedResponse.results
                        self.newChaptersLoaded = true
                        
                        if ( seasonalMangaLoaded ) {
                            loadCovers()
                        }
                        
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "(From TodayView, featuredManga) Unknown error when parsing response from server.\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
            }
        }.resume()
    }
    //MARK: - Get covers for newest chapters
    func loadCovers() {
        let loadingDescription: LocalizedStringKey = "Retrieving covers..."
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "100"))
        
        for chapter in newChapters {
            urlComponents.queryItems?.append(URLQueryItem(name: "manga[]", value: chapter.mangaId))
        }
        
        for manga in seasonalDisplayedManga {
            urlComponents.queryItems?.append(URLQueryItem(name: "manga[]", value: manga.id))
        }
        
        let payload = urlComponents.percentEncodedQuery
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")cover?\(payload ?? "")") else {
            print("Invalid URL")
            return
        }
        
        appState.loadingQueue.append(loadingDescription)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From TodayView(loadNewestChaptersCovers): \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(Covers.self, from: data)
                    
                    var dict: [String: String] = [:]
                    for cover in decodedResponse.results {
                        dict[cover.mangaId] = cover.path
                    }
                    
                    DispatchQueue.main.async {
                        self.coversByMangaId = dict
                        
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        appState.errorMessage += "(From TodayView, newestChapters, covers) Unknown error when parsing response from server.\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
            }
        }.resume()
    }
    //MARK: - Get newest mangas
    func getNewestTitles() {
        let loadingDescription: LocalizedStringKey = "Loading newest manga..."
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")manga?limit=20&order[createdAt]=desc&includes[]=cover_art") else {
            print("Invalid URL")
            return
        }
        
        appState.loadingQueue.append(loadingDescription)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From TodayView(loadNewestMangas): \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(ReturnedMangas.self, from: data)
                    
                    DispatchQueue.main.async {
                        newDisplayedMangas = decodedResponse.results
                        
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                } catch {
                    DispatchQueue.main.async {
                        appState.errorMessage += "(From TodayView, newestManga) Unknown error when parsing response from server.\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
            }
        }.resume()
    }
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
