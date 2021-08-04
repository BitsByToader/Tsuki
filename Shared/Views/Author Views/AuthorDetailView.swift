//
//  AuthorDetailView.swift
//  iOS
//
//  Created by Tudor Ifrim on 31.07.2021.
//

import SwiftUI
import SDWebImageSwiftUI

struct AuthorDetailView: View {
    var author: Author
    
    @State private var mangas: [Manga] = []
    
    var body: some View {
        List {
            Section(header: Text("Details")) {
                HStack {
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
                    
                    Text(author.name)
                        .font(.title2)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                if author.biography != "" {
                    Text(author.biography)
                        .font(.body)
                } else {
                    HStack {
                        Spacer()
                        
                        Text("No biography yet...")
                            .bold()
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 25)
                        
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("Mangas written by author")) {
                if mangas.isEmpty {
                    Text("Loading manga...")
                        .bold()
                        .foregroundColor(.gray)
                }
                
                ForEach(mangas, id: \.title ) { manga in
                    NavigationLink(destination: MangaView(manga: manga, mangaDetailsAlreadyLoaded: true, reloadContents: true, mangaId: manga.id)) {
                        HStack {
                            WebImage(url: URL(string: manga.coverURL))
                                .resizable()
                                .placeholder {
                                    Rectangle().foregroundColor(.gray)
                                        .opacity(0.2)
                                        .frame(width: 80, height: 110)
                                }
                                .indicator(.activity)
                                .transition(.fade(duration: 0.5))
                                .scaledToFit()
                                .frame(width: 80)
                                .cornerRadius(5)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(manga.title)
                                    .font(.title2)
                                    .bold()
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                                
                                Text(manga.description)
                                    .font(.body)
                                    .lineLimit(3)
                                    .foregroundColor(Color(.gray))
                            }
                        }
                    }
                }
            }
        }.navigationTitle("Author info")
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            var urlComponents = URLComponents()
            urlComponents.queryItems = []
            
            urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "100"))
            urlComponents.queryItems?.append(URLQueryItem(name: "includes[]", value: "cover_art"))
            urlComponents.queryItems?.append(URLQueryItem(name: "includes[]", value: "author"))
            urlComponents.queryItems?.append(URLQueryItem(name: "includes[]", value: "artist"))
            
            for id in author.mangaIdsFromAuthor {
                urlComponents.queryItems?.append(URLQueryItem(name: "ids[]", value: id))
            }
            
            guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")manga?\(urlComponents.percentEncodedQuery ?? "")") else {
                print("From MangaView: Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.httpShouldHandleCookies = true
            
            print("From AuthorDetailView: \(url.absoluteString)")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data {
                    do {
                        struct Response: Decodable {
                            let results: [Manga]
                        }
                        
                        let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
                        
                        DispatchQueue.main.async {
                            self.mangas = decodedResponse.results
                        }
                    } catch {
                        print(error)
                    }
                } else {
                    print(error as Any)
                }
            }.resume()
        }
    }
}
