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
import SDWebImageSwiftUI

struct SearchByNameView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var searchInput: String = ""
    var includedTagsToSearch: [String] = []
    var excludedTagsToSearch: [String] = []
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
        let loadingDescription: LocalizedStringKey = "Loading mangas..."
        appState.loadingQueue.append(loadingDescription)
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "30"))
        
        if ( searchInput != "" ) {
            let q1 = URLQueryItem(name: "title", value: searchInput)
            urlComponents.queryItems?.append(q1)
        }
        
        if ( !includedTagsToSearch.isEmpty ) {
            for tag in includedTagsToSearch {
                let q = URLQueryItem(name: "includedTags[]", value: tag)
                urlComponents.queryItems?.append(q)
            }
        }
        
        if ( !excludedTagsToSearch.isEmpty ) {
            for tag in excludedTagsToSearch {
                let q = URLQueryItem(name: "excludedTags[]", value: tag)
                urlComponents.queryItems?.append(q)
            }
        }
        
        let payload = urlComponents.percentEncodedQuery
        
        guard let url = URL(string: "https://api.mangadex.org/manga?\(payload ?? "")") else {
            print("From SearchByName: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(ReturnedMangas.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.searchResult = decodedResponse.results
                        appState.removeFromLoadingQueue(loadingState: "Loading mangas...")
                    }
                    
                    return
                } catch {
                    print(error)
                    
                    DispatchQueue.main.async {
                        appState.errorMessage += "Error from SearchByName.\nUnknown error when parsing response from server: \n\n \(error)\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                    
                    return
                }
            }
            
            DispatchQueue.main.async {
                print("Error from SearchByName.\nFetch failed: \(error?.localizedDescription ?? "Unknown error")")
                appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                withAnimation {
                    appState.errorOccured = true
                    appState.removeFromLoadingQueue(loadingState: loadingDescription)
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
