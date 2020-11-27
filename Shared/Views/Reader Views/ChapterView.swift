//
//  ChapterView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/07/2020.
//

import SwiftUI
import Introspect

struct ChapterView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("readingDataSaver") var readingDataSaver: Bool = false
    @AppStorage("readerStyle") var readerStyle: String = ReaderSettings.ReaderStyle.Scroll.rawValue
    @AppStorage("readerOrientation") var readerOrientation: String = ReaderSettings.ReaderOrientation.Horizontal.rawValue
    @AppStorage("fancyAnimations") var fancyAnimations: Bool = true
    
    var loadContents: Bool
    
    //Set to nil to dismiss the current view, like when the user finished reading (don't do this tho, just an example)
    @Binding var isViewPresented: Int?
    
    var remainingChapters: [ChapterData]
    var remainingLocalChapters: [DownloadedChapter] = []
    
    @State private var pageURLs: [String] = []
    
    private var readingProgress: Int {
        if pageURLs.count == 0 {
            return 0
        } else {
            print("Reading progress is: \(( (currentPage + 1) *  100 ) / pageURLs.count)")
            return ( (currentPage + 1) *  100 ) / pageURLs.count
        }
    }
    @State private var currentPage: Int = 0
    @State private var extraProgressIsShown: Bool = false
    @State private var chapterRead: Int = 0
    
    @State private var navBarHidden: Bool = false
    @State private var settingsPresented: Bool = false
    
    var navTitle: String {
        if loadContents {
            if remainingChapters.isEmpty {
                return "Please select a chapter."
            } else {
                return remainingChapters[chapterRead].title! != "" ? remainingChapters[chapterRead].title! : "Ch. \(remainingChapters[chapterRead].chapter)"
            }
        } else {
            if remainingLocalChapters.isEmpty {
                return "Please select a chapter."
            } else {
                return remainingLocalChapters[chapterRead].wrappedTitle != "" ? remainingLocalChapters[chapterRead].wrappedTitle : "Ch. \(remainingLocalChapters[chapterRead].wrappedChapter)"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if !pageURLs.isEmpty {
                if readerStyle == "Scroll" {
                    ScrollReader(readerStyle: $readerStyle,
                                 navBarHidden: $navBarHidden,
                                 pages: pageURLs,
                                 contentIsRemote: loadContents,
                                 currentPage: $currentPage,
                                 currentChapter: $chapterRead,
                                 remainingChapters: (loadContents ? remainingChapters.count : remainingLocalChapters.count),
                                 loadChapter: loadChapter)
                        .onTapGesture {
                            withAnimation {
                                navBarHidden.toggle()
                            }
                        }
                } else if readerStyle == "Swipe" {
                    SwipeReader(fancyAnimations: fancyAnimations,
                                readerOrientation: readerOrientation,
                                pages: $pageURLs,
                                contentIsRemote: loadContents,
                                currentPage: $currentPage,
                                currentChapter: $chapterRead,
                                remainingChapters: (loadContents ? remainingChapters.count : remainingLocalChapters.count),
                                loadChapter: loadChapter)
                        .onTapGesture {
                            withAnimation {
                                navBarHidden.toggle()
                            }
                        }.if(navBarHidden) { $0.edgesIgnoringSafeArea(.all) }
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
                        
                        Text("\(currentPage + 1) of \(pageURLs.count)")
                            .foregroundColor(Color(.systemGray))
                            .bold()
                    }.frame(minWidth: 50, maxWidth: 100, maxHeight: 25)
                    .opacity(extraProgressIsShown ? 1 : 0)
                    .animation(.default)
                    .padding(5)
                    .onTapGesture {
                        extraProgressIsShown.toggle()
                    }
                }.opacity(navBarHidden ? 0 : 1)
            }
        }.introspectTabBarController { (UITabBarController) in
            UITabBarController.tabBar.isHidden = navBarHidden
        }
        .sheet(isPresented: $settingsPresented) {
            ReaderSettings(settingsPresented: $settingsPresented)
        }
        .onAppear {
            loadChapter(currentChapter: 0)
        }.navigationBarItems(trailing: Button(action: {settingsPresented.toggle()}, label: {Image(systemName: "gear")}))
        .navigationBarTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(navBarHidden)
    }
    
    func loadChapter(currentChapter: Int) {
        //Check if the chapter to be loaded isn't a scheldued chapter
        if ( !remainingChapters.isEmpty && Date().timeIntervalSince1970 - (remainingChapters[currentChapter].timestamp ?? 0) < 0 ) {
            if ( currentChapter == 0 ) {
                isViewPresented = nil
            }
            
            return
        }
        
        let loadingDescription: LocalizedStringKey = "Loading chapter..."
        
        if !loadContents && !remainingLocalChapters.isEmpty {
            let chapterPages = remainingLocalChapters[currentChapter].wrappedPages
            for page in chapterPages {
                pageURLs += [getDocumentsDirectory().appendingPathComponent(page).path]
            }
            return
        }
        
        if remainingChapters.isEmpty && remainingLocalChapters.isEmpty {
            return
        }
        
        appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "https://mangadex.org/api/v2/chapter/\(remainingChapters[currentChapter].chapterId)?saver=\(readingDataSaver)") else {
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
                    
                    for page in decodedResponse.data.pages {
                        pages.append(decodedResponse.data.baseURL + decodedResponse.data.mangaHash + "/" + page)
                    }
                    
                    DispatchQueue.main.async {
                        self.pageURLs += pages
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                    return
                } catch {
                    DispatchQueue.main.async {
                        appState.errorMessage += "An error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n"
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
