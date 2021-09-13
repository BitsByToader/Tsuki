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
    //MARK: - Environment variables
    @EnvironmentObject var appState: AppState
    //MARK: - Variables
    @State private var searchInput: String = ""
    
    @Binding var tagsToSearchWith: [Tag]
    var removeToggledTagByIndex: (Int) -> Void
    
    var preloadManga: Bool = false
    var sectionName: String = ""
    
    @State private var searchResult: [ReturnedManga] = []
    
    private let numberOfItemsToLoad: Int = 50
    @State private var loadCounter: Int = 0
    @State private var loadLimit: Int = 1
    //MARK: - SwiftUI Views
    var body: some View {
        ScrollView {
            HStack {
                Image(systemName: "magnifyingglass")
                
                TextField("Search", text: $searchInput, onCommit: {
                    self.hideKeyboard()
                    self.searchResult = []
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
            .navigationBarItems(trailing: Button( "Refresh", action: { loadContent(refresh: true) } ))
            
            if tagsToSearchWith.contains(where: { $0.state == .enabled }) {
                TagsGridView(tags: $tagsToSearchWith,
                             tagStateToDisplay: .enabled,
                             tagColorToDisplay: .systemGreen,
                             headline: "Included tags",
                             removeTag: removeToggledTagByIndex,
                             reloadList: searchManga)
                    .padding(.horizontal, 5)
                    .transition(.opacity)
                    .animation(.default)
            }
            
            if tagsToSearchWith.contains(where: { $0.state == .disabled }) {
                TagsGridView(tags: $tagsToSearchWith,
                             tagStateToDisplay: .disabled,
                             tagColorToDisplay: .systemRed,
                             headline: "Excluded tags",
                             removeTag: removeToggledTagByIndex,
                             reloadList: searchManga)
                    .padding(.horizontal, 5)
                    .transition(.opacity)
                    .animation(.default)
            }
            
            MangaGrid(dataSource: searchResult, reachedTheBottom: { loadContent(refresh: false) })
            
            Spacer()
        }.onAppear {
            if preloadManga {
                loadContent(refresh: false)
            }
        }
    }
    //MARK: - Load content
    func loadContent(refresh: Bool) {
        if ( refresh ) {
            self.loadCounter = 0
            self.searchResult = []
        }
        
        if ( loadCounter * numberOfItemsToLoad <= loadLimit ) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .soft)
            hapticFeedback.impactOccurred()
            
            searchManga()
        } else {
            let hapticFeedback = UINotificationFeedbackGenerator()
            hapticFeedback.notificationOccurred(.warning)
        }
    }
    //MARK: - Search manga method
    func searchManga() {
        let loadingDescription: LocalizedStringKey = "Loading mangas..."
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "\(numberOfItemsToLoad)"))
        urlComponents.queryItems?.append(URLQueryItem(name: "offset", value: "\(loadCounter * numberOfItemsToLoad)"))
        
        if ( searchInput != "" ) {
            let q1 = URLQueryItem(name: "title", value: searchInput)
            urlComponents.queryItems?.append(q1)
        }
        
        for tag in tagsToSearchWith {
            var queryName: String = ""
            
            if tag.state == .enabled {
                queryName = "includedTags[]"
            } else if tag.state == .disabled {
                queryName = "excludedTags[]"
            }
            
            let q = URLQueryItem(name: queryName, value: tag.id)
            urlComponents.queryItems?.append(q)
        }
        
        urlComponents.queryItems?.append( URLQueryItem(name: "includes[]", value: "cover_art") )
        
        let payload = urlComponents.percentEncodedQuery
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")manga?\(payload ?? "")") else {
            print("From SearchByName: Invalid URL")
            return
        }
        
        appState.loadingQueue.append(loadingDescription)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(ReturnedMangas.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.loadCounter += 1
                        self.loadLimit = decodedResponse.total
                        
                        self.searchResult += decodedResponse.data
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


#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
