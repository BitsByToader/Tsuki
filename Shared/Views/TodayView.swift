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
    @State private var newChaptersCovers: [String: String] = [:]
    
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
                            if newChapters.isEmpty {
                                ForEach(0..<6) {_ in
                                    PlaceholderManga()
                                }
                            } else {
                                ForEach(newChapters, id: \.self) { manga in
                                    NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.mangaId)) {
                                        UpdatedManga(manga: manga, coverArt: newChaptersCovers[manga.mangaId] ?? "", mangaTitle: manga.mangaTitle)
                                    }.buttonStyle(PlainButtonStyle())
                                    .frame(width: 125)
                                }
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
                            if featuredDisplayedMangas.isEmpty {
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
            
            MangaView(reloadContents: !featuredDisplayedMangas.isEmpty, mangaId: featuredDisplayedMangas.isEmpty ? "" : featuredDisplayedMangas[0].id)

            ChapterView(loadContents: false, isViewPresented: .constant(1), remainingChapters: [])
            
        }.if( sizeClass == .regular ) { $0.navigationViewStyle(DoubleColumnNavigationViewStyle()) }
        .if( sizeClass == .compact ) { $0.navigationViewStyle(StackNavigationViewStyle()) }
        .onAppear {
            loadFeaturedManga()
            getNewestTitles()
            loadNewestChapters()
        }
    }
    //MARK: - Get featured manga
    func loadFeaturedManga() {
        let loadingDescription: LocalizedStringKey = "Loading featured manga..."
        
        appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "https://api.mangadex.org/list/8018a70b-1492-4f91-a584-7451d7787f7a?includes[]=manga") else {
            print("Invalid URL")
            return
        }
        
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
                            arr.append(ReturnedManga(title: relation.mangaTitle, coverArtURL: "", id: relation.id))
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.featuredDisplayedMangas = arr
                        
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
        
        appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "https://api.mangadex.org/chapter?limit=20&order[createdAt]=desc&translatedLanguage[]=en&includes[]=manga") else {
            print("Invalid URL")
            return
        }
        
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
                        
                        loadNewestChaptersCovers()
                        
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
    //MARK: - Get covers for newest chapters and featured manga
    func loadNewestChaptersCovers() {
        let loadingDescription: LocalizedStringKey = "Retrieving covers..."
        
        appState.loadingQueue.append(loadingDescription)
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "100"))
        
        var arr: [String] = []
        for chapter in newChapters {
            if !arr.contains(chapter.mangaId) {
                arr.append(chapter.mangaId)
                urlComponents.queryItems?.append(URLQueryItem(name: "manga[]", value: chapter.mangaId))
            }
        }
        print(arr.count)
        
        for manga in featuredDisplayedMangas {
            urlComponents.queryItems?.append(URLQueryItem(name: "manga[]", value: manga.id))
        }
        
        print (urlComponents.queryItems?.count)
        
        let payload = urlComponents.percentEncodedQuery
        
        guard let url = URL(string: "https://api.mangadex.org/cover?\(payload ?? "")") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From TodayView(loadNewestChaptersCovers): \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(Covers.self, from: data)
                    
                    DispatchQueue.main.async {
                        for cover in decodedResponse.results {
                            newChaptersCovers[cover.manga] = cover.path
                        }
                        
                        print (decodedResponse.results.count)
                        print(newChaptersCovers.keys.count)
                        
                        for (index, manga) in featuredDisplayedMangas.enumerated() {
                            featuredDisplayedMangas[index].coverArtURL = newChaptersCovers[manga.id] ?? ""
                        }
                        
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
        
        appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "https://api.mangadex.org/manga?limit=20&order[createdAt]=desc&includes[]=cover_art") else {
            print("Invalid URL")
            return
        }
        
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
