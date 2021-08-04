//
//  LatestUpdatesView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 16/08/2020.
//

import SwiftUI
import SDWebImageSwiftUI

//MARK: - LatestUpdates View
struct LatestUpdatesView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var widgetURL: WidgetURL
    @EnvironmentObject var appState: AppState
    
    @State private var result: [Chapter] = []
    
    var mangaTitleDict: [String: String] = [:]
    var coverArtDict: [String: String] = [:]
    
    var body: some View {
        
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
                if result.isEmpty {
                    ForEach(0..<12) { _ in
                        PlaceholderManga()
                    }
                } else {
                    ForEach(result, id: \.self) { manga in
                        NavigationLink(destination: MangaView(reloadContents: true, mangaId: manga.mangaId)) {
                            UpdatedManga(manga: manga, coverArt: coverArtDict[manga.mangaId] ?? "", mangaTitle: mangaTitleDict[manga.mangaId] ?? "")
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Spacer()
                .navigationTitle(Text("Latest Updates"))
        }.onAppear {
            self.widgetURL.openedWithURL = false
            
            let loadingDescription: LocalizedStringKey = "Checking for account..."
            DispatchQueue.main.async {
                appState.loadingQueue.append(loadingDescription)
            }
            
            MDAuthentification.standard.logInProcedure { isLoggedIn in
                if isLoggedIn {
                    print("Loading library...")
                    
                    
                    loadManga()
                    
                    DispatchQueue.main.async {
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                } else {
                    print("Showing log in view...")
                    
                    DispatchQueue.main.async {
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        
                        //Should never reach here, because we already do this check in the previous view (LibraryView)
                        //But if we do, just pop the view from the stack.
//                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }.onOpenURL { url in
            if ( url == URL(string: "tsuki:///latestupdates") ) {
                //Broken atm...
                
                /*let loadingDescription: LocalizedStringKey = "Checking for account..."
                DispatchQueue.main.async {
                    appState.loadingQueue.append(loadingDescription)
                }
                
                MDAuthentification.standard.logInProcedure { isLoggedIn in
                    if isLoggedIn {
                        loadManga()
                        
                        DispatchQueue.main.async {
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    } else {
                        print("Showing log in view...")
                        
                        DispatchQueue.main.async {
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                            print("mhm wut?")
                        }
                    }
                }*/
            }
        }
    }
    
    //MARK: - Load manga method
    func loadManga() {
        let loadingDescription: LocalizedStringKey = "Loading updates..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "500"))
        urlComponents.queryItems?.append(URLQueryItem(name: "order[publishAt]", value: "desc"))
        
        let pickedLanguages = UserDefaults(suiteName: "group.TsukiApp")?.stringArray(forKey: "pickedLanguages") ?? []
        
        for lang in pickedLanguages {
            urlComponents.queryItems?.append(URLQueryItem(name: "translatedLanguage[]", value: lang))
        }
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "")user/follows/manga/feed?\(urlComponents.percentEncodedQuery ?? "")") else {
            print("From LatestUpdatesView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(MDAuthentification.standard.getSessionToken())", forHTTPHeaderField: "Authorization")
        
        print("From LatestUpdatesView: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 204 {
                    DispatchQueue.main.async {
                        self.result = []
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    return
                }
            }
            
            if let data = data {
                do {
                    struct Results: Decodable {
                        let results: [Chapter]
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(Results.self, from: data)
                    
                    
                    DispatchQueue.main.async {
                        self.result = decodedResponse.results.sorted {
                            return (ISO8601DateFormatter().date(from: $0.timestamp) ?? Date()).timeIntervalSince1970 > (ISO8601DateFormatter().date(from: $1.timestamp) ?? Date()).timeIntervalSince1970
                        }
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                    return
                }  catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "(From LatestUpdates) Unknown error when parsing response from server.\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
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

//MARK: - UpdatedMangaView
struct UpdatedManga: View {
    let manga: Chapter
    
    let coverArt: String
    let mangaTitle: String
    
    var body: some View {
        VStack {
            WebImage(url: URL(string: coverArt))
                .resizable()
                .placeholder {
                    Rectangle().foregroundColor(.gray)
                        .opacity(0.2)
                }
                .indicator(.activity)
                .cornerRadius(8)
                .transition(.fade(duration: 0.5))
                .scaledToFit()
                .frame(height: 180)
                
            
            Label(labelText:   (ISO8601DateFormatter().date(from: manga.timestamp) ?? Date()).timeAgoDisplay(style: .short)  )
            Label(labelText: "Vol. \(manga.volume) Ch. \(manga.chapter)")
            
            Text("\(languagesEmojiDict[manga.chapterLanguageCode] ?? "")\(mangaTitle)")
                .multilineTextAlignment(.center)
            
            Spacer()
        }.frame(height: 300)
    }
}

//MARK: - Label View struct
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

extension Date {
    func timeAgoDisplay(style: RelativeDateTimeFormatter.UnitsStyle) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.formattingContext = .standalone
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
