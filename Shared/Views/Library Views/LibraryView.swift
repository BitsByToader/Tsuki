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

struct LibraryView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var widgetURL: WidgetURL
    @EnvironmentObject var appState: AppState

    @State private var loggedIn: Bool = false
    
    @State private var shouldOpenLatestUpdates: Bool = false
    
    @State private var searchInput: String = ""
    @State private var showCancelButton: Bool = false
    @State private var logInViewPresented: Bool = false
    var tagsToSearch: String = ""
    
    @State private var searchResult: [ReturnedManga] = []
    
    @State private var mangaTitleByIdDict: [String: String] = [:]
    @State private var coverArtByIdDict: [String: String] = [:]
    
    var body: some View {
        if loggedIn {
            NavigationView {
                ScrollView {
                    //MARK: - Search Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            
                            TextField("Search library...", text: $searchInput, onEditingChanged: { isEditing in
                                self.showCancelButton = true
                            }, onCommit: {
                                print("onCommit")
                            }).foregroundColor(.primary)
                            
                            Button(action: {
                                self.searchInput = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .opacity(searchInput == "" ? 0 : 1)
                            }
                        }.padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                        .foregroundColor(.secondary)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10.0)
                        
                        if showCancelButton  {
                            Button("Cancel") {
                                UIApplication.shared.endEditing(true) // this must be placed before the other commands here
                                self.searchInput = ""
                                self.showCancelButton = false
                            }.animation(.default)
                            .foregroundColor(Color(.systemBlue))
                        }
                    }.padding(.horizontal)
                    .animation(.default)
                    //MARK: - Links
                    NavigationLink(destination: LatestUpdatesView(mangaTitleDict: mangaTitleByIdDict, coverArtDict: coverArtByIdDict).environmentObject(widgetURL).environmentObject(appState)) { //, isActive: $shouldOpenLatestUpdates broken atm
                        LibraryLink(linkTitle: "Latest Updates")
                    }
                    
                    NavigationLink(destination: DownloadedMangaView()) {
                        LibraryLink(linkTitle: "Downloaded manga")
                    }
                    //MARK: - Manga
                    MangaGrid(dataSource: searchResult.filter { $0.title.contains(searchInput) || searchInput == "" })
                        .navigationTitle(Text("Library"))
                    
                    Spacer()
                }.onTapGesture {
                    UIApplication.shared.endEditing(true)
                    self.showCancelButton = false
                }
                .onAppear {
                    //Check if the app was opened from the widget, and if it was, go to the latest updates view
                    //Also, keep this as-is, with the if statement, or else, shouldOpenLatestUpdates will be bound to widgetURL.openedWithURL
                    //Thus, it would the latest updated view will get dismissed as soon as it loaded
                    if ( widgetURL.openedWithURL ) {
                        shouldOpenLatestUpdates = true
                    }
                }
                
                MangaView(reloadContents: true, mangaId: "d1c0d3f9-f359-467c-8474-0b2ea8e06f3d")

                ChapterView(loadContents: true, isViewPresented: .constant(1), remainingChapters: [])
                
            }.if( sizeClass == .regular ) { $0.navigationViewStyle(DoubleColumnNavigationViewStyle()) }
            .if ( sizeClass == .compact ) { $0.navigationViewStyle(StackNavigationViewStyle()) }
            .onOpenURL { url in
                if ( url == URL(string: "tsuki:///latestupdates") ) {
                    self.shouldOpenLatestUpdates = true
                }
            }
        } else {
            NavigationView {
                VStack(spacing: 10) {
                    Spacer()
                    
                    SignInRequiredView(description: "Your library will be available once you sign in.", logInViewPresented: $logInViewPresented)
                    
                    NavigationLink(destination: DownloadedMangaView(), label: {
                        Text("...or you can view your downloaded mangas")
                            .multilineTextAlignment(.center)
                    })
                    Spacer()
                    Spacer()
                }
            }.navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let loadingDescription: LocalizedStringKey = "Checking for account..."
                DispatchQueue.main.async {
                    appState.loadingQueue.append(loadingDescription)
                }
                
                MDAuthentification.standard.logInProcedure { isLoggedIn in
                    if isLoggedIn {
                        print("Loading library...")
                        
                        
                        loadLibrary()
                        
                        DispatchQueue.main.async {
                            loggedIn = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    } else {
                        print("Showing log in view...")
                        
                        DispatchQueue.main.async {
                            loggedIn = false
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                            logInViewPresented = true
                        }
                    }
                }
            }
        }
    }
    //MARK: - Retrieve the mangas in the library
    func loadLibrary() {
        let loadingDescription: LocalizedStringKey = "Loading library..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        guard let url = URL(string: "https://api.mangadex.org/user/follows/manga?limit=100") else {
            print("From LibraryView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(MDAuthentification.standard.getSessionToken())", forHTTPHeaderField: "Authorization")
        
        print("From LibraryView: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 204 {
                    DispatchQueue.main.async {
                        self.searchResult = []
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    return
                }
            }
            
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(ReturnedMangas.self, from: data)
                    
                    for manga in decodedResponse.results {
                        mangaTitleByIdDict[manga.id] = manga.title
                    }
                    
                    DispatchQueue.main.async {
                        searchResult = decodedResponse.results
                        
                        loadCovers()
                        
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                    return
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Unknown error when parsing response from server.\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
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
    //MARK: - Retrieve the covers for the mangas in the library
    func loadCovers() {
        let loadingDescription: LocalizedStringKey = "Retrieving covers..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "100"))
        
        for manga in searchResult {
            urlComponents.queryItems?.append(URLQueryItem(name: "manga[]", value: manga.id))
        }
        
        let payload = urlComponents.percentEncodedQuery
        
        guard let url = URL(string: "https://api.mangadex.org/cover?\(payload ?? "")") else {
            print("From LibraryView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("From LibraryView(cover loading): \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(Covers.self, from: data)
                    
                    for cover in decodedResponse.results {
                        coverArtByIdDict[cover.manga] = cover.path
                    }
                    
                    DispatchQueue.main.async {
                        for (index, manga) in searchResult.enumerated() {
                            searchResult[index].coverArtURL = coverArtByIdDict[manga.id] ?? ""
                        }
                        
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Unknown error when getting covers (library).\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
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

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged{_ in
        print("Dragged")
        UIApplication.shared.endEditing(true)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}
