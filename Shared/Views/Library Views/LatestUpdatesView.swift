//
//  LatestUpdatesView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 16/08/2020.
//

import SwiftUI
import SwiftSoup
import SDWebImageSwiftUI

struct ReturnedUpdatedManga: Hashable {
    let title: String
    let coverArtURL: String
    let id: String
    let timeOfUpdate: String
    let volumeAndChapter: String
}

struct LatestUpdatesView: View {
    @EnvironmentObject var widgetURL: WidgetURL
    @EnvironmentObject var appState: AppState
    
    private var loggedIn: Bool {
        return checkLogInStatus()
    }
    
    @State private var result: [ReturnedUpdatedManga] = []
    
    var body: some View {
        
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                if result.isEmpty {
                    ForEach(0..<12) { _ in
                        PlaceholderManga()
                    }
                } else {
                    ForEach(result, id: \.self) { manga in
                        NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.id)) {
                            UpdatedManga(manga: manga)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Spacer()
                .navigationTitle(Text("Latest Updates"))
        }.onAppear {
            self.widgetURL.openedWithURL = false
            if (loggedIn) {
                loadManga()
            }
        }.onOpenURL { url in
            if ( url == URL(string: "tsuki:///latestupdates") ) {
                if ( loggedIn ) {
                    loadManga()
                }
            }
        }
    }
    
    func loadManga() {
        let loadingDescription = "Loading updates..."
        appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "https://mangadex.org") else {
            print("From LatestUpdatesView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From LatestUpdatesView: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    
                    let doc: Document = try SwiftSoup.parse(String(data: data, encoding: .utf8)!)
                    
                    let returnedMangas = try doc.getElementById("follows_update")?.child(0).children().array()
                    
                    var mangas: [ReturnedUpdatedManga] = []
                    
                    for manga in returnedMangas ?? [] {
                        let title: String = try manga.child(1).getElementsByClass("manga_title").first()!.text()
                        
                        let mangaLink: String = try manga.child(1).getElementsByClass("manga_title").first()!.attr("href")
                        let mangaId: String = mangaLink.components(separatedBy: "/")[2]
                        
                        let coverArt: String = try manga.getElementsByClass("sm_md_logo").first()!.select("a").select("img").attr("src")
                        
                        let timeOfUpdate: String = try manga.children().array()[2].select("a").text()
                        let chapter: String = try manga.children().array()[4].text()
                        
                        mangas.append(ReturnedUpdatedManga(title: title, coverArtURL: coverArt, id: mangaId, timeOfUpdate: timeOfUpdate, volumeAndChapter: chapter))
                    }
                    
                    DispatchQueue.main.async {
                        self.result = mangas
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                    return
                } catch Exception.Error(let type, let message) {
                    print ("Error of type \(type): \(message)")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Error when parsing response from server. \nType: \(type) \nMessage: \(message)\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Unknown error when parsing response from server.\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
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
            }
        }.resume()
    }
}

struct UpdatedManga: View {
    let manga: ReturnedUpdatedManga
    
    var body: some View {
        VStack {
            WebImage(url: URL(string: manga.coverArtURL))
                .resizable()
                .placeholder {
                    Rectangle().foregroundColor(.gray)
                        .opacity(0.2)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFit()
                .frame(height: 180)
            
            Label(labelText: manga.timeOfUpdate)
            Label(labelText: manga.volumeAndChapter)
            
            Text(manga.title)
                .multilineTextAlignment(.center)
            
            Spacer()
        }.frame(height: 300)
    }
}

struct Label: View {
    var labelText: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .background(Color(.secondarySystemBackground))
                .opacity(0.15)
                .cornerRadius(12)
            
            Text("\(labelText)")
                .foregroundColor(Color(.white))
                .truncationMode(.middle)
                .padding(.leading, 5)
                .padding(.trailing, 5)
        }.padding(.leading, 10)
        .padding(.trailing, 10)
        .padding(.top, 0)
        .padding(.bottom, 0)
        .frame(height: 15)
    }
}
