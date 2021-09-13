//
//  AuthorListView.swift
//  iOS
//
//  Created by Tudor Ifrim on 28.07.2021.
//

import SwiftUI
import SDWebImageSwiftUI

struct AuthorListView: View {
    @EnvironmentObject var appState: AppState
    var authorIds: [String]
    
    @State private var authors: [Author] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(authors, id: \.id) { author in
                    NavigationLink( destination: AuthorDetailView(author: author) ) {
                        HStack(spacing: 5) {
                            WebImage(url: URL(string: author.imageUrl))
                                .resizable()
                                .placeholder {
                                    Rectangle().foregroundColor(.gray)
                                        .opacity(0.2)
                                        .frame(width: 75, height: 100)
                                }
                                .indicator(.activity)
                                .transition(.fade(duration: 0.5))
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(5)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(author.name)
                                    .font(.title2)
                                    .bold()
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Mangas written by author: \(author.mangaIdsFromAuthor.count)")
                                    .font(.body)
                                    .lineLimit(2)
                                    .foregroundColor(Color(.gray))
                                
                                Spacer()
                            }
                        }
                    }
                }
            }.navigationTitle("Author list")
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitleDisplayMode(.large)
        }.onAppear {
            getAuthorsWithIds(ids: authorIds)
        }
    }
    
    func getAuthorsWithIds(ids: [String]) {
        let loadingDescription: LocalizedStringKey = "Loading authors..."
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "100"))
        
        for id in ids {
            urlComponents.queryItems?.append(URLQueryItem(name: "ids[]", value: id))
        }
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")author?\(urlComponents.percentEncodedQuery ?? "")") else {
            print("From MangaView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From AuthorListView: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    struct Authors: Decodable {
                        let data: [Author]
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(Authors.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.authors = decodedResponse.data
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                    
                } catch {
                    print(error)
                    
                    DispatchQueue.main.async {
                        appState.errorMessage += "From Manga (chapter loading).\nAn error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                    
                    return
                }
                
                return
            } else {
                print(error ?? "")
                
                DispatchQueue.main.async {
                    appState.errorMessage += "Message: \(String(describing: error))\n\n URL: \(url.absoluteString)\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
            }
        }.resume()
        
        return
    }
}
