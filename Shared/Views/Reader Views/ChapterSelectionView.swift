//
//  ChapterSelectionView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/08/2020.
//

import SwiftUI

struct ChapterSelectionView: View {
    @Environment(\.managedObjectContext) var moc
    @AppStorage("downloadingDataSaver") var downloadingDataSaver: Bool = false
    
    @Binding var isPresented: Bool
    var manga: Manga
    var chapters: [Chapter]
    
    @State var selectedChapters: [Bool]
    private var numberOfSelectedChapters: Int {
        var number: Int = 0
        
        for index in 0..<selectedChapters.count {
            if selectedChapters[index] {
                number += 1
            }
        }
        
        return number
    }
    
    @State private var pages: [Pages] = []
    @State private var downloadStarted: Bool = false
    @State private var gatheringInfo: Bool = false
    @State private var pageInProgress: Double = 0
    private var pageCount: Double {
        var number: Double = 0
        
        for page in pages {
            for _ in page.array {
                number += 1
            }
        }
        
        return number
    }
    
    struct Pages: Equatable {
        var array: [Page]
        let chapter: Chapter
        
        struct Page: Equatable {
            let pagePath: String
            var pageSaved: Bool
        }
    }
    
    enum Selection {
        case allChapters
        case chaptersUntil
        case chaptersInbetween
        case selectedChapters
    }
    
    @State private var selection: Selection = .selectedChapters
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Text("Select chapters")
                    .bold()
                    .font(.largeTitle)
                Spacer()
                VStack(alignment: .leading, spacing: 15) {
                    Picker("Chapters", selection: $selection) {
                        Text("All")
                            .tag(Selection.allChapters)
                        
                        Text("Until")
                            .tag(Selection.chaptersUntil)
                        
                        Text("Inbetween")
                            .tag(Selection.chaptersInbetween)
                        
                        Text("Selected")
                            .tag(Selection.selectedChapters)
                    }.pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selection) { choice in
                        updateSelectedChapters(choice)
                    }
                    
                    List(Array(chapters.enumerated()), id: \.element) { index, chapter in
                        Button(action: {
                            selectedChapters[index].toggle()
                            selection = .selectedChapters
                        }) {
                            HStack {
                                Text("Vol.\(chapter.volume) Ch.\(chapter.chapter) \(languagesEmojiDict[chapter.chapterLanguageCode] ?? "")")
                                
                                Spacer()
                                
                                HStack {
                                    Text("Selected")
                                        .font(Font.headline.smallCaps())
                                    Image(systemName: "checkmark")
                                }.foregroundColor(Color.accentColor)
                                .opacity(selectedChapters[index] ? 1 : 0)
                                .animation(.default)
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
                Spacer()
                
                Button(action: initDownload) {
                    Text("Download Chapters")
                        .bold()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                }
                Button(action: {
                    for index in 0..<selectedChapters.count {
                        selectedChapters[index] = false
                    }
                }) {
                    Text("Deselect all")
                }.padding()
            }.opacity( !(gatheringInfo || downloadStarted) ? 1 : 0)
            .animation(.default)
            
            ProgressView(label: {
                Text("Gathering chapter info...")
            }).opacity(gatheringInfo ? 1 : 0)
            .animation(.default)
            
            ProgressView(value: pageInProgress, total: pageCount, label: {
                HStack {
                    Spacer()
                    Text("Downloading chapter(s)...")
                    Spacer()
                }
            }).opacity(downloadStarted ? 1 : 0)
            .animation(.default)
            .padding(.horizontal)
        }
        
        Spacer()
            .onChange(of: pages) { pages in
                print("Pages count is \(pages.count)")
                if (pages.count == numberOfSelectedChapters && gatheringInfo) {
                    gatheringInfo = false
                    downloadStarted = true
                    
                    UIApplication.shared.isIdleTimerDisabled = true
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        //Don't know if i should use saveChapters or saveChaptersAsync...
                        //Did a quick test with a random 24 page chapter and Async scored 36s
                        //While the regular one did 43s. However, the strain on MangaDex's servers
                        //is far greater with the Async one. Don't know what I should do... Will leave both in
                        //and I'll decide later. Currently, I'll use the regular one since it is easier to understand
                        //and might be more reliable as well...
                        
                        saveChapters()
                    }
                }
            }
        
    }
    
    func updateSelectedChapters(_ choice : Selection) {
        switch choice {
        case .allChapters:
            for index in 0..<selectedChapters.count {
                selectedChapters[index] = true
            }
        case .chaptersInbetween:
            var foundFirstChapter: Bool = false
            for index in 0..<selectedChapters.count {
                if !selectedChapters[index] && foundFirstChapter {
                    selectedChapters[index] = true
                } else if selectedChapters[index] && !foundFirstChapter {
                    foundFirstChapter = true
                } else if selectedChapters[index] && foundFirstChapter {
                    break
                }
            }
        case .chaptersUntil:
            for index in 0..<selectedChapters.count {
                if selectedChapters[index] {
                    break
                } else {
                    selectedChapters[index] = true
                }
            }
        case .selectedChapters:
            return
        }
    }
    
    func initDownload() {
        downloadStarted = false
        gatheringInfo = true
        for index in 0..<selectedChapters.count {
            if ( selectedChapters[index] ) {
                getChapterPages(chapter: chapters[index])
            }
        }
    }
    //MARK: - Synchronous chapter saving
    func saveChapters() {
        let mangaToDownload = DownloadedManga(context: moc)

        mangaToDownload.mangaArtist = manga.artist[0]
        mangaToDownload.mangaCoverURL = manga.coverURL
        mangaToDownload.mangaId = UUID()
        mangaToDownload.mangaTitle = manga.title
        mangaToDownload.mangaRating = "\(manga.rating.bayesian)"
        mangaToDownload.mangaTags = manga.tags
        mangaToDownload.mangaDescription = manga.description
        mangaToDownload.usersRated = "\(manga.rating.users)"

        for index in 0..<pages.count {
            let chapter = DownloadedChapter(context: moc)

            chapter.title = self.pages[index].chapter.title
            chapter.chapter = self.pages[index].chapter.chapter + " " +  (languagesEmojiDict[self.pages[index].chapter.chapterLanguageCode] ?? "")
            chapter.volume = self.pages[index].chapter.volume
            chapter.timestamp = self.pages[index].chapter.timestamp

            //insert string array here that contains image url paths
            var imagePaths: [String] = []

            for j in 0..<pages[index].array.count {
                print("Attempting to save image number \(j)")
                guard let url = URL(string: pages[index].array[j].pagePath) else {
                    print("From chapter selection view, invalid url")
                    break
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.httpShouldHandleCookies = true

                let (data, _, error) = URLSession.shared.synchronousDataTask(with: request)
                if let error = error {
                    print("Error downloading page: \(error)")
                    #warning("MAKE SURE TO KEEP IN STORAGE ALL OF THE IMAGE PATHS SO YOU CAN DELETE THEM IF AN ERROR OCCURS")
                    //also, i shouldn't revert everything if an error pops up. Just stop the process, inform the user, and leave everything else still intact
                    self.moc.rollback()
                    DispatchQueue.main.async {
                        self.isPresented = false
                    }
                } else {
                    let imageName: String = "\(self.pages[index].chapter.chapterId)\(j+1).png"
                    let filename = getDocumentsDirectory().appendingPathComponent(imageName)

                    do {
                        try data!.write(to: filename)
                    } catch {
                        print("Error when saving image: \(error)")
                    }
                    print("Should've written to storage image: \(filename)")

                    imagePaths += [imageName]
                    DispatchQueue.main.async {
                        withAnimation {
                            self.pageInProgress += 1
                        }
                    }
                }
            }
            print("Downloaded pages for chapter \(self.pages[index].chapter.chapterId)")
            chapter.pages = imagePaths
            chapter.origin = mangaToDownload
        }

        print("Done...")
        try? self.moc.save()

        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
            self.isPresented = false
        }
    }
    //MARK: - Asynchronous chapter saving
    func saveChaptersAsync() {
        let mangaToDownload = DownloadedManga(context: moc)
        
        mangaToDownload.mangaArtist = manga.artist[0]
        mangaToDownload.mangaCoverURL = manga.coverURL
        mangaToDownload.mangaId = UUID()
        mangaToDownload.mangaTitle = manga.title
        mangaToDownload.mangaRating = "\(manga.rating.bayesian)"
        mangaToDownload.mangaTags = manga.tags
        mangaToDownload.mangaDescription = manga.description
        mangaToDownload.usersRated = "\(manga.rating.users)"
        
        for index in 0..<pages.count {
            let chapter = DownloadedChapter(context: moc)
            
            chapter.title = self.pages[index].chapter.title
            chapter.chapter = self.pages[index].chapter.chapter + " " +  (languagesEmojiDict[self.pages[index].chapter.chapterLanguageCode] ?? "")
            chapter.volume = self.pages[index].chapter.volume
            chapter.timestamp = self.pages[index].chapter.timestamp
            
            print("Starting to download chapter: \(chapter.wrappedChapter)")
            //insert string array here that contains image url paths
            var imagePaths: [String] = []
            
            for j in 0..<pages[index].array.count {
                print("Attempting to save image number \(j)")
                guard let url = URL(string: pages[index].array[j].pagePath) else {
                    print("From chapter selection view, invalid url")
                    break
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.httpShouldHandleCookies = true
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    let imageName: String = "\(self.pages[index].chapter.chapterId)\(j+1).png"
                    let filename = getDocumentsDirectory().appendingPathComponent(imageName)
                    
                    do {
                        try data!.write(to: filename)
                    } catch {
                        print("Error when saving image: \(error)")
                    }
                    print("Should've written to storage image: \(filename)")
                    
                    imagePaths += [imageName]
                    self.pages[index].array[j].pageSaved = true
                    DispatchQueue.main.async {
                        withAnimation {
                            self.pageInProgress += 1
                        }
                    }
                    
                    for smth in self.pages[index].array {
                        if ( !smth.pageSaved ) {
                            return
                        }
                    }

                    print("Downloaded pages for chapter \(self.pages[index].chapter.chapterId)")
                    imagePaths = imagePaths.sorted {
                        Int($0.prefix($0.count - 4))! < Int($1.prefix($1.count - 4))!
                    }
                    
                    chapter.pages = imagePaths
                    chapter.origin = mangaToDownload
                    
                    for smth in pages {
                        for smthelse in smth.array {
                            if ( !smthelse.pageSaved ) {
                                return
                            }
                        }
                    }
                    
                    print("Done...")
                    try? self.moc.save()
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isIdleTimerDisabled = false
                        self.isPresented = false
                    }
                    
                    return
                }.resume()
            }
        }
    }
    
    func getChapterPages(chapter: Chapter) {
        //appState.isLoading = true
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "")at-home/server/\(chapter.chapterId)") else {
            print("From ChapterSelectionView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    struct Result: Decodable {
                        let baseUrl: String
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(Result.self, from: data)
                    
                    var pages: [Pages.Page] = []
                    
                    if downloadingDataSaver {
                        for chapterPage in chapter.dataSaverPages {
                            let pagePath: String = decodedResponse.baseUrl + "/data-saver/" + chapter.hash + "/" + chapterPage
                            let pageToAppend: Pages.Page = Pages.Page(pagePath: pagePath, pageSaved: false)
                            pages.append(pageToAppend)
                        }
                    } else {
                        for chapterPage in chapter.dataPages {
                            let pagePath: String = decodedResponse.baseUrl + "/data/" + chapter.hash + "/" + chapterPage
                            let pageToAppend: Pages.Page = Pages.Page(pagePath: pagePath, pageSaved: false)
                            pages.append(pageToAppend)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.pages += [Pages(array: pages, chapter: chapter)]
                    }
                    
                    return
                } catch {
                    DispatchQueue.main.async {
                        isPresented = false
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                isPresented = false
            }
            return
        }.resume()
    }
}

extension View {
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

extension URLSession {
    func synchronousDataTask(with urlRequest: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: urlRequest) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}

//struct ChapterSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChapterSelectionView()
//    }
//}
