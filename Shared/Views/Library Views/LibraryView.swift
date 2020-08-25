//
//  SearchByNameView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 24/07/2020.
//

// Shamefully ripped off the UITableView search implementation from this answer on StackOverflow
// https://stackoverflow.com/a/58473985
// I will replace with something native if Apple decides to give the people what the people want i.e a fucken search bar
// on a navigationview with a list inside of it

import SwiftUI
import SwiftSoup
import SDWebImageSwiftUI

#warning("TODO: implement searching of saved mangas from the text field")

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var searchInput: String = ""
    var tagsToSearch: String = ""
    
    @State private var searchResult: [ReturnedManga] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                HStack {
                    Image(systemName: "magnifyingglass")
                    
                    TextField("Search", text: $searchInput, onCommit: {
                        self.hideKeyboard()
                        searchManga()
                    }).foregroundColor(.primary)
                    
                    Button(action: {
                        self.searchInput = ""
                        self.hideKeyboard()
                    }) {
                        Image(systemName: "xmark.circle.fill").opacity(searchInput == "" ? 0 : 1)
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                .foregroundColor(.secondary)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10.0)
                .padding(.horizontal)
                .padding(.bottom, 0)
                .navigationTitle(Text("Library"))
                
                NavigationLink(destination: LatestUpdatesView()) {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                            .cornerRadius(7)

                        HStack {
                            Text("Latest Updates")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }.padding(5)
                    }.padding(15)
                    .padding(.top, 0)
                    .frame(height: 75)
                }
                
                MangaGrid(dataSource: searchResult)
                
                Spacer()
            }.onAppear {
                appState.isLoading = true
                searchManga()
            }
        }
    }
    
    func searchManga() {
        guard let url = URL(string: "https://mangadex.org/list/915553") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    
                    let doc: Document = try SwiftSoup.parse(String(data: data, encoding: .utf8)!)
                    
                    let returnedMangas = try doc.getElementsByClass("manga-entry").array()
                    
                    var mangas: [ReturnedManga] = []
                    
                    for manga in returnedMangas {
                        let title: String = try manga.getElementsByClass("manga_title").first()!.text()
                        let mangaId: String = try manga.attr("data-id")
                        
                        var coverArt: String = try manga.getElementsByClass("large_logo").first()!.select("a").select("img").attr("src")
                        coverArt = "https://mangadex.org" + coverArt
                        
                        
                        mangas.append(ReturnedManga(title: title, coverArtURL: coverArt, id: mangaId))
                    }
                    
                    DispatchQueue.main.async {
                        searchResult = mangas
                        appState.isLoading = false
                    }
                    
                    return
                } catch Exception.Error(let type, let message) {
                    print ("Error of type \(type): \(message)")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Error when parsing response from server. \nType: \(type) \nMessage: \(message)\n\n"
                        withAnimation {
                            appState.errorOccured = true
                        }
                    }
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Unknown error when parsing response from server.\n\n"
                        withAnimation {
                            appState.errorOccured = true
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                    }
                }
            }
        }.resume()
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchByNameView()
    }
}
