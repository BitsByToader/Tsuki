//
//  ChapterView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct ChapterView: View {
    @EnvironmentObject var appState: AppState
    var remainingChapters: [Chapter]
    
    @State private var pageURLs: [String] = []
    
    var chapter: PageData?
    
    @State private var readingProgress: Int = 0
    @State private var currentPage: Int = 0
    @State private var extraProgressIsShown: Bool = false
    @State private var chapterRead: Int = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack {
                    ForEach(Array(pageURLs.enumerated()), id: \.offset) { index, page in
                        WebImage(url: URL(string: page))
                            .resizable()
                            .placeholder {
                                Rectangle().foregroundColor(.gray)
                                    .opacity(0.2)
                            }
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFit()
                            .onAppear {
                                currentPage = index + 1
                                getReadingStatus(index: index+1)
                                
                                if ( currentPage + 1 == pageURLs.count && chapterRead + 1 != remainingChapters.count ) {
                                    chapterRead += 1
                                    loadChapter(currentChapter: chapterRead)
                                }
                            }
                    }
                }
            }
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 5) {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: ( geometry.size.width * CGFloat(readingProgress) ) / 100, height: 5)
                        .animation(.default)
                        .onTapGesture {
                            extraProgressIsShown.toggle()
                        }
                    
                    ZStack {
                        BlurView(style: .prominent)
                            .cornerRadius(5)
                            .frame(minWidth: 50)
                        
                        Text("\(currentPage) of \(pageURLs.count)")
                    }.frame(minWidth: 50, maxWidth: 100, maxHeight: 25)
                    .opacity(extraProgressIsShown ? 1 : 0)
                    .animation(.default)
                    .padding(5)
                    .onTapGesture {
                        extraProgressIsShown.toggle()
                    }
                }
            }
        }.onAppear {
            loadChapter(currentChapter: 0)
        }.navigationBarTitle(remainingChapters[chapterRead].chapterInfo.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func loadChapter(currentChapter: Int) {
        appState.isLoading = true
        
        guard let url = URL(string: "https://mangadex.org/api/chapter/\(remainingChapters[currentChapter].chapterId)") else {
            print("From ChapterView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(PageData.self, from: data)
                    
                    var pages: [String] = []
                    
                    for page in decodedResponse.pages {
                        pages.append(decodedResponse.baseURL + decodedResponse.mangaHash + "/" + page)
                    }
                    
                    DispatchQueue.main.async {
                        self.pageURLs += pages
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
    
    func getReadingStatus(index: Int) {
        readingProgress = ( index *  100 ) / pageURLs.count
        print("Index is \(index), thus progress is: \(readingProgress)")
    }
}

//struct ChapterView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChapterView()
//    }
//}
