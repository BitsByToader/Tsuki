//
//  MangaView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 27/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct MangaView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var appState: AppState
    
    @State var manga: Manga = Manga()
    
    @State var chapters: [Chapter] = [] //chapters -- remoteChapters
    @State var localChapters: [DownloadedChapter] = []
    
    @State var reloadContents: Bool
    
    @State private var descriptionExpanded: Bool = false
    @State private var chapterDownloadingViewPresented: Bool = false
    @State private var presentAlert: Bool = false
    @State private var currentStatus: String = "Status"
    @State private var statusSheetPresented: Bool = false
    private var statusActions: [ActionSheet.Button] {
        var statusButtons: [ActionSheet.Button] = []
        
        if mangaId != "" {
            statusButtons.append(.destructive(Text("Unfollow"), action: {
                updateMangaStatus(statusId: 0)
                currentStatus = "Status"
            }))
        }
        
        for index in 1..<MangaStatus.allCases.count {
            statusButtons.append(.default(Text(MangaStatus.allCases[index].rawValue), action: {
                updateMangaStatus(statusId: index)
            }))
        }
        
        statusButtons.append(.cancel())
        
        return statusButtons
    }
    
    var mangaId: String
    
    enum MangaStatus: String, CaseIterable {
        case unfollow = "Unfollow"
        case reading = "Reading"
        case completed = "Completed"
        case onHold = "On Hold"
        case planning = "Plan to read"
        case dropped = "Dropped"
        case reReading = "Re-Reading"
    }
    
    let MDMangaStatus: [MangaStatus: String] = [
        .reading : "reading",
        .completed: "completed",
        .dropped: "dropped",
        .onHold: "on_hold",
        .planning: "plan_to_read",
        .reReading: "re_reading",
        .unfollow: "unfollow"
    ]
    
    var body: some View {
        List {
            //MARK: - Header
            MangaViewTitle(manga: manga)
            //MARK: - Manga actions
            HStack {
                Spacer()
                
                VStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                    Text(currentStatus)
                        .multilineTextAlignment(.center)
                }
                .padding(5)
                .actionSheet(isPresented: $statusSheetPresented) {
                    ActionSheet(title: Text("Change reading status to..."),
                                buttons: statusActions)
                }
                .hoverEffect(.automatic)
                .foregroundColor(Color(.systemBlue))
                .onTapGesture(perform: {
                    statusSheetPresented.toggle()
                })
                
                Divider()
                
                VStack(spacing: 3) {
                    Image(systemName: "play.fill")
                    Text("Resume")
                }.padding(15)
                .hoverEffect(.automatic)
                .foregroundColor(Color(.systemBlue))
                .alert(isPresented: $presentAlert) {
                    Alert(title: Text("Coming soon...™️"), message: Text("This feature is currently unavailable. It will be coming soon in an update, so hang tight!"), dismissButton: Alert.Button.cancel(Text("OK")))
                }
                .onTapGesture {
                    self.presentAlert = true
                }
                
                Divider()
                
                VStack(spacing: 3) {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Download")
                }.padding(5)
                .hoverEffect(.automatic)
                .foregroundColor(Color(.systemBlue))
                .onTapGesture {
                    chapterDownloadingViewPresented = true
                }.sheet(isPresented: $chapterDownloadingViewPresented, onDismiss: {
                    //just in case smth fucks up, I don't want to leave the user's screen turned on
                    UIApplication.shared.isIdleTimerDisabled = false
                }) {
                    ChapterSelectionView(isPresented: $chapterDownloadingViewPresented, manga: manga, chapters: chapters.reversed(), selectedChapters: [Bool](repeating: false, count: chapters.count))
                        .environment(\.managedObjectContext, moc)
                }
                
                Spacer()
            }
            //MARK: - Description
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
            //MARK: - Tags
            VStack(alignment: .leading) {
                Text("Genres")
                    .font(.title2)
                    .bold()
                
                MangaViewTags(tagsToDisplay: manga.tags)
            }
            //MARK: - Chapters
            VStack(alignment: .leading, spacing: 10) {
                Text("Chapters")
                    .font(.title2)
                    .bold()
                
                if chapters.isEmpty && localChapters.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("No chapters available")
                            .font(.title3)
                            .bold()
                            .foregroundColor(Color(.lightGray))
                            .frame(height: 200)
                        Spacer()
                    }
                    Spacer()
                } else {
                    if localChapters.isEmpty {
                        MangaViewChapterList(chapters: chapters, remote: true)
                    } else {
                        MangaViewChapterList(chapters: [], remote: false, localChapters: localChapters)
                    }
                }
            }
        }.onAppear{
            if reloadContents {
                DispatchQueue.global(qos: .utility).async {
                    loadMangaInfo { wasSuccesfull in
                        if wasSuccesfull {
                            loadChapters()
                            getMangaStatus()
                            getAuthorDetails()
                        }
                    }
                    self.reloadContents = false
                }
            }
        }.navigationTitle(mangaId != "" ? manga.title : "Please select a manga to read.")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(PlainListStyle())
    }
    
    //MARK: - Manga details loader
    func loadMangaInfo(completion: @escaping (Bool) -> Void) {
        let loadingDescription: LocalizedStringKey = "Loading manga information..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        guard let url = URL(string: "https://api.mangadex.org/manga/\(mangaId)") else {
            print("From MangaView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(Manga.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.manga = decodedResponse
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        completion(true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        appState.errorMessage += "From Manga (manga loading).\nAn error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                    
                    completion(false)
                }
            } else {
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
                
                completion(false)
            }
        }.resume()
    }
    //MARK: - Chapter loader
    func loadChapters() {
        let loadingDescription: LocalizedStringKey = "Loading manga chapters..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        guard let url = URL(string: "https://api.mangadex.org/manga/\(mangaId)/feed?locales[]=en") else {
            print("From MangaView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 204 {
                    DispatchQueue.main.async {
                        self.chapters = []
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
                        self.chapters = decodedResponse.results.sorted {
                            return Double($0.chapter) ?? 0 > Double($1.chapter) ?? 0
                        }
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
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
                
                return
            }
        }.resume()
    }
    //MARK: - Update the reading status of the manga
    func updateMangaStatus(statusId: Int) {
        let loadingDescription: LocalizedStringKey = "Updating status..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        guard let url = URL(string :"https://api.mangadex.org/manga/\(mangaId)/status") else {
            print("from updateMangaStatus: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("Bearer \(MDAuthentification.standard.getSessionToken())", forHTTPHeaderField: "Authorization")
        
        let status: String = statusId != 0 ? "\"\(MDMangaStatus[MangaStatus.allCases[statusId]] ?? "reading")\"" : "null"
        let payload = Data("{\"status\":\(status)}".utf8)
        
        print(status)
        print(url.absoluteString)
        
        URLSession.shared.uploadTask(with: request, from: payload) { data, response, error in
            if let data = data {
                do {
                    struct Response: Decodable {
                        let result: String
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
                    
                    print(decodedResponse.result)
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                            
                            let hapticFeedback = UINotificationFeedbackGenerator.init()
                            
                            if ( decodedResponse.result == "ok" ) {
                                hapticFeedback.notificationOccurred(.success)
                                currentStatus = MangaStatus.allCases[statusId].rawValue
                            }
                        }
                    }
                    return
                } catch {
                    print(error)
                    
                    DispatchQueue.main.async {
                        appState.errorMessage += "From Manga (manga status update).\nAn error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            let hapticFeedback = UINotificationFeedbackGenerator.init()
                            hapticFeedback.notificationOccurred(.error)
                            
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                    
                    return
                }
            }
            
            DispatchQueue.main.async {
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                withAnimation {
                    let hapticFeedback = UINotificationFeedbackGenerator.init()
                    hapticFeedback.notificationOccurred(.error)
                    
                    appState.errorOccured = true
                    appState.removeFromLoadingQueue(loadingState: loadingDescription)
                }
            }
        }.resume()
    }
    
    //MARK: - Get manga status method
    func getMangaStatus() {
        let loadingDescription: LocalizedStringKey = "Loading status..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        guard let url = URL(string :"https://api.mangadex.org/manga/\(mangaId)/status") else {
            print("from updateMangaStatus: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.setValue("Bearer \(MDAuthentification.standard.getSessionToken())", forHTTPHeaderField: "Authorization")
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    struct Response: Decodable {
                        let result: String
                        let status: String?
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
                    
                    var newStatus: String = "Status"
                    for key in MDMangaStatus.keys {
                        if ( MDMangaStatus[key] == (decodedResponse.status ?? "unfollow") ) {
                            newStatus = key.rawValue
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {
                        currentStatus = newStatus
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                } catch {
                    print(error)
                    
                    DispatchQueue.main.async {
                        appState.errorMessage += "From Manga (status retrieval).\nAn error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                    
                    return
                }
            } else {
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
                
                return
            }
        }.resume()
    }
    //MARK: - Authoer loader method
    func getAuthorDetails() {
        let loadingDescription: LocalizedStringKey = "Loading author..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        guard let url = URL(string :"https://api.mangadex.org/author/\(manga.artist[1])") else {
            print("from updateMangaStatus: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(Author.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.manga.artist[0] = decodedResponse.authorName
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                } catch {
                    print(error)
                    
                    DispatchQueue.main.async {
                        appState.errorMessage += "From Manga (author retrieval).\nAn error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                    
                    return
                }
            } else {
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
                
                return
            }
        }.resume()
    }
}

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        MangaView(reloadContents: false, mangaId: "1")
    }
}
