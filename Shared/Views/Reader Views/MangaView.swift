//
//  MangaView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 27/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct MangaView: View {
    @EnvironmentObject var appState: AppStates
    
    @State private var manga: Manga = Manga(title: "", artist: "", coverURL: "", description: "", rating: Manga.Rating(bayesian: "", users: ""))
    @State private var chapters: [Chapter] = []
    
    @State var reloadContents: Bool
    
    @State private var descriptionExpanded: Bool = false
    
    var mangaId: String
    
    var body: some View {
        List {
            HStack(alignment: .top) {
                WebImage(url: URL(string: manga.coverURL))
                    .resizable()
                    .placeholder {
                        Rectangle().foregroundColor(.gray)
                            .opacity(0.2)
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
                    .frame(width: 100)
                    .cornerRadius(5)
                
                VStack(alignment: .leading) {
                    Text(manga.title)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    
                    Text(manga.artist)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(Color(.gray))
                    
                    Text("\(manga.rating.bayesian) || \(manga.rating.users)")
                }
            }
            
            VStack(alignment: .leading) {
                Text("Description")
                    .font(.title2)
                    .bold()
                
                Text(manga.description)
                    .padding(.top, 5)
            }.frame(maxHeight: descriptionExpanded ? .infinity : 200)
            .onTapGesture {
                descriptionExpanded.toggle()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Chapters")
                    .font(.title2)
                    .bold()
                
                List {
                    ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                        NavigationLink(destination: ChapterView(remainingChapters: chapters.reversed().suffix(index+1))) {
                            HStack {
                                Text("Vol.\(chapter.chapterInfo.volume!) Ch.\(chapter.chapterInfo.chapter!)")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(chapter.chapterInfo.title!)")
                                    .allowsTightening(true)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.5)
                            }
                        }
                    }
                }.frame(height: 200)
            }
            
        }.onAppear{
            if reloadContents {
                appState.isLoading = true
                loadMangaInfo()
                self.reloadContents = false
            }
        }.navigationTitle(manga.title)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(PlainListStyle())
    }
    
    func loadMangaInfo() {
        guard let url = URL(string: "https://mangadex.org/api/manga/\(mangaId)") else {
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
                    let decodedResponse = try JSONDecoder().decode(MangaDataModel.self, from: data)
                    
                    var filteredChapters: [Chapter] = []
                    
                    for chapter in decodedResponse.chapters {
                        if ( chapter.chapterInfo.langCode == "gb" ) {
                            filteredChapters.append(chapter)
                        }
                    }
                    
                    //Sort the array starting with the chapter that is the newest
                    // i.e. the one with the biggest "time" value
                    
                    filteredChapters = filteredChapters.sorted {
                        $0.chapterInfo.timestamp! > $1.chapterInfo.timestamp!
                    }
                    //I would like however to change the sorting mode to something more intricate
                    //Like sorting based on volume/chapter, so I would display the latest chapter, not the newest one
                    //which isn't always the same thing
                    
                    DispatchQueue.main.async {
                        self.manga = decodedResponse.manga
                        self.manga.coverURL = "https://mangadex.org" + decodedResponse.manga.coverURL
                        self.chapters = filteredChapters
                        appState.isLoading = false
                    }
                    
                    return
                } catch {
                    DispatchQueue.main.async {
                        appState.errorMessage += "An error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n"
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

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        MangaView(reloadContents: false, mangaId: "1")
    }
}
