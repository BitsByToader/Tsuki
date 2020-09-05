//
//  ChapterSelectionView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/08/2020.
//

import SwiftUI

struct ChapterSelectionView: View {
    @Environment(\.managedObjectContext) var moc
    
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
    
    struct Pages: Equatable {
        var array: [String]
        let chapter: Chapter
    }
    
    enum Selection {
        case allChapters
        case chaptersUntil
        case chaptersInbetween
        case selectedChapters
    }
    
    @State private var selection: Selection = .selectedChapters
    
    var body: some View {
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
                            Text("Vol.\(chapter.chapterInfo.volume ?? "") Ch.\(chapter.chapterInfo.chapter)")
                            
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
            
            Spacer()
                .onChange(of: pages) { pages in
                    print("Pages count is \(pages.count)")
                    if pages.count == numberOfSelectedChapters {
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
        for index in 0..<selectedChapters.count {
            if ( selectedChapters[index] ) {
                getChapterPages(chapter: chapters[index], chapterId: chapters[index].chapterId)
            }
        }
    }
    
    func saveChapters() {
//        UIApplication.shared.isIdleTimerDisabled = true
//        Use this ^^^ to prevent the screen from dimming while downloading chapters
//        Don't forget to set it back to false after the download is finished
//        Or when an error is encountered. If you forget this one, the screen won't dim
//        until the is completely restarted
        
        let mangaToDownload = DownloadedManga(context: moc)
        
        mangaToDownload.mangaArtist = manga.artist
        mangaToDownload.mangaCoverURL = manga.coverURL
        mangaToDownload.mangaId = UUID()
        mangaToDownload.mangaTitle = manga.title
        mangaToDownload.mangaRating = manga.rating.bayesian
        mangaToDownload.mangaTags = manga.tags
        mangaToDownload.mangaDescription = manga.description
        mangaToDownload.usersRated = manga.rating.users
        
        for index in 0..<pages.count {
//            let chapter = DownloadedChapter(context: moc)
//
//            chapter.title = self.pages[index].chapter.chapterInfo.title
//            chapter.chapter = self.pages[index].chapter.chapterInfo.chapter
//            chapter.volume = self.pages[index].chapter.chapterInfo.volume
//            chapter.timestamp = self.pages[index].chapter.chapterInfo.timestamp!
            
            //insert string array here that contains image url paths
            for j in 0..<pages[index].array.count {
                print("Attempting to save image number \(j)")
                guard let url = URL(string: pages[index].array[j]) else {
                    print("From chapter selection view, invalid url")
                    break
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.httpShouldHandleCookies = true
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data {
                        let imageName: String = "\(self.pages[index].chapter.chapterId)\(j+1).png"
                        
                        //Replace the remote URL of the image used for downloading it, with the local name constructed earlier^^^
                        //When the for loop that goes through the pages.array is finished, the array will have all local URLs ready...
                        
                        self.pages[index].array[j] = imageName
                        
                        
                        let filename = getDocumentsDirectory().appendingPathComponent(imageName)
                        try? data.write(to: filename)
                        
                        print("Wrote to storage image name: \(filename.absoluteString)")
                        
                        if ( j == (pages[index].array.count - 1) ) {
                            print("Reached final page!")
                            saveToCD(manga: mangaToDownload, index: index)
                        }
                        
                        return
                    }
                }.resume()
            }
            
//            chapter.origin = mangaToDownload
        }
        
//        try? self.moc.save()
//
//        self.isPresented = false
    }
    
    func saveToCD(manga: DownloadedManga, index: Int) {
        print("Reached saveToCD with index \(index)")
        
        let chapter = DownloadedChapter(context: moc)
        
        chapter.title = self.pages[index].chapter.chapterInfo.title
        chapter.chapter = self.pages[index].chapter.chapterInfo.chapter
        chapter.volume = self.pages[index].chapter.chapterInfo.volume
        chapter.timestamp = self.pages[index].chapter.chapterInfo.timestamp!
        
        chapter.pages = self.pages[index].array
        
        chapter.origin = manga
        
        if ( index == (pages.count - 1) ) {
            finishSave()
        }
    }
    
    func finishSave() {
        print("Finished save!")
        try? self.moc.save()
        self.isPresented = false
    }
    
    func getChapterPages(chapter: Chapter, chapterId: String) {
        //appState.isLoading = true
        
        guard let url = URL(string: "https://mangadex.org/api/chapter/\(chapterId)") else {
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
                    let decodedResponse = try JSONDecoder().decode(PageData.self, from: data)
                    
                    var pages: [String] = []
                    
                    for page in decodedResponse.pages {
                        pages.append(decodedResponse.baseURL + decodedResponse.mangaHash + "/" + page)
                        print("\(decodedResponse.baseURL + decodedResponse.mangaHash + "/" + page)")
                    }
                    
                    DispatchQueue.main.async {
//                        self.pages += [pages]
                        self.pages += [Pages(array: pages, chapter: chapter)]
                    }
                    
                    return
                } catch {
//                    DispatchQueue.main.async {
//                        appState.errorMessage += "An error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n"
//                        withAnimation {
//                            appState.errorOccured = true
//                            appState.isLoading = false
//                        }
//                    }
                }
                
//                DispatchQueue.main.async {
//                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
//                    withAnimation {
//                        appState.errorOccured = true
//                        appState.isLoading = false
//                    }
//                }
            }
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
