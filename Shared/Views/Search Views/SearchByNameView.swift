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

struct SearchByNameView: View {
    @EnvironmentObject var appState: AppStates
    
    @State private var searchInput: String = ""
    var tagsToSearch: String = ""
    var preloadManga: Bool = false
    var sectionName: String = ""
    
    @State private var searchResult: [ReturnedManga] = []
    
    var body: some View {
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
            .padding(.bottom, 15)
            .navigationTitle(Text(sectionName != "" ?  "\(sectionName) manga" : "Search by name"))
            
            MangaGrid(dataSource: searchResult)
            
            Spacer()
        }.onAppear {
            if preloadManga {
                searchManga()
            }
        }
    }
    
    func searchManga() {
        appState.isLoading = true
        
        let stringToSearch: String = searchInput
        
        var urlComponents = URLComponents()
        let q1 = URLQueryItem(name: "title", value: stringToSearch)
        let q2 = URLQueryItem(name: "tags", value: tagsToSearch)
        urlComponents.queryItems = [q1, q2]
        let payload = urlComponents.percentEncodedQuery
        
        guard let url = URL(string: "https://mangadex.org/search?\(payload ?? "")") else {
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

struct SearchByNameView_Previews: PreviewProvider {
    static var previews: some View {
        SearchByNameView(sectionName: "Some")
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
