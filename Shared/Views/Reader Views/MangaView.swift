//
//  MangaView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 27/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct MangaView: View {
    //MARK: - Environment variables
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var appState: AppState
    //MARK: - Variables
    @State var manga: Manga = Manga()
    @State var mangaDetailsAlreadyLoaded: Bool = false
    
    @State var chapters: [Chapter] = [] //chapters -- remoteChapters
    @State var localChapters: [DownloadedChapter] = []
    
    private let numberOfChaptersToLoad: Int = 100
    @State private var loadCounter: Int = 0
    @State private var loadLimit: Int = 1
    
    @State var reloadContents: Bool
    
    @State private var descriptionExpanded: Bool = false
    
    @State private var chapterDownloadingViewPresented: Bool = false
    @State private var presentAlert: Bool = false
    @State private var statusSheetPresented: Bool = false
    @State private var authorDetailSheetPresented: Bool = false
    
    @State private var currentStatus: String = "Status"
    private var statusActions: [ActionSheet.Button] {
        var statusButtons: [ActionSheet.Button] = []
        
        if mangaId != "" {
            statusButtons.append(.destructive(Text("Unfollow"), action: {
                
                let loadingDescription: LocalizedStringKey = "Checking for account..."
                DispatchQueue.main.async {
                    appState.loadingQueue.append(loadingDescription)
                }
                
                MDAuthentification.standard.logInProcedure { isLoggedIn in
                    print("Loading library...")
                    
                    if isLoggedIn {
                        updateMangaStatus(statusId: 0)
                    }
                    
                    DispatchQueue.main.async {
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
                
                currentStatus = "Status"
            }))
        }
        
        for index in 1..<MangaStatus.allCases.count {
            statusButtons.append(.default(Text(MangaStatus.allCases[index].rawValue), action: {
                let loadingDescription: LocalizedStringKey = "Checking for account..."
                DispatchQueue.main.async {
                    appState.loadingQueue.append(loadingDescription)
                }
                
                MDAuthentification.standard.logInProcedure { isLoggedIn in
                    print("Loading library...")
                    
                    if isLoggedIn {
                        updateMangaStatus(statusId: index)
                    }
                    
                    DispatchQueue.main.async {
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                }
            }))
        }
        
        statusButtons.append(.cancel())
        
        return statusButtons
    }
    
    var mangaId: String
    //MARK: - Dictionaries
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
    //MARK: - SwiftUI Views
    var body: some View {
        List {
            //MARK: - Header
            MangaViewTitle(authorDetailsPresented: $authorDetailSheetPresented, manga: manga)
                .sheet(isPresented: $authorDetailSheetPresented, content: {
                    AuthorListView(authorIds: manga.artistId)
                        .environmentObject(appState)
                })
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
                    .lineLimit(descriptionExpanded ? nil : 6)
            }.onTapGesture {
                descriptionExpanded.toggle()
            }.animation(.default)
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
                        MangaViewChapterList(remoteChapters: chapters, reachedTheBottom: loadChapters )
                    } else {
                        MangaViewChapterList(localChapters: localChapters)
                    }
                }
            }
        }.onAppear{
            if reloadContents {
                loadContent(refresh: false)
            }
        }.navigationTitle(mangaId != "" ? manga.title : "Please select a manga to read.")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button( "Refresh", action: { loadContent(refresh: true) } ))
        .listStyle(PlainListStyle())
    }
    //MARK: - Load content method
    func loadContent(refresh: Bool) {
        if ( refresh ) {
            self.manga = Manga()
            self.chapters = []
            self.loadCounter = 0
        }
        
        let loadingDescription: LocalizedStringKey = "Checking for account..."
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        MDAuthentification.standard.logInProcedure { isLoggedIn in
            print("Loading library...")
            
            if mangaDetailsAlreadyLoaded {
                loadChapters()
                
                if isLoggedIn {
                    getMangaStatus()
                }
                
                //Basically, we will use the already filled manga object only the first time.
                //If the user reloads, then we will fetch the manga details (along with all the other stuff) from the network.
                mangaDetailsAlreadyLoaded = false
            } else {
                loadMangaInfo { wasSuccesfull in
                    if wasSuccesfull {
                        loadChapters()
                        
                        if isLoggedIn {
                            getMangaStatus()
                        }
                    }
                }
            }
            
            self.reloadContents = false
            
            DispatchQueue.main.async {
                appState.removeFromLoadingQueue(loadingState: loadingDescription)
            }
        }
    }
    //MARK: - Manga details loader
    func loadMangaInfo(completion: @escaping (Bool) -> Void) {
        let loadingDescription: LocalizedStringKey = "Loading manga information..."
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")manga/\(mangaId)?includes[]=author&includes[]=artist&includes[]=cover_art") else {
            print("From MangaView: Invalid URL")
            return
        }
        
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
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
        if ( loadCounter * numberOfChaptersToLoad > loadLimit ) {
            let hapticFeedback = UINotificationFeedbackGenerator()
            hapticFeedback.notificationOccurred(.warning)
            
            return
        }
        
        let hapticFeedback = UIImpactFeedbackGenerator(style: .soft)
        hapticFeedback.impactOccurred()
        
        let loadingDescription: LocalizedStringKey = "Loading manga chapters..."
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "\(numberOfChaptersToLoad)"))
        urlComponents.queryItems?.append(URLQueryItem(name: "offset", value: "\(loadCounter * numberOfChaptersToLoad)"))
        urlComponents.queryItems?.append(URLQueryItem(name: "order[chapter]", value: "desc"))
        urlComponents.queryItems?.append(URLQueryItem(name: "order[volume]", value: "desc"))
        
        let pickedLanguages = UserDefaults(suiteName: "group.TsukiApp")?.stringArray(forKey: "pickedLanguages") ?? []
        
        for lang in pickedLanguages {
            urlComponents.queryItems?.append(URLQueryItem(name: "translatedLanguage[]", value: lang))
        }
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")manga/\(mangaId)/feed?\(urlComponents.percentEncodedQuery ?? "")") else {
            print("From MangaView: Invalid URL")
            return
        }
        
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
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
                        let total: Int
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(Results.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.loadCounter += 1
                        self.loadLimit = decodedResponse.total
                        
                        self.chapters += decodedResponse.results
                        
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        getReadMarkers()
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
    //MARK: - Get list of read markers
    func getReadMarkers() {
        let loadingDescription: LocalizedStringKey = "Loading read markers..."
        
        guard let url = URL(string :"\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")manga/\(mangaId)/read") else {
            print("from updateMangaStatus: Invalid URL")
            return
        }
        
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.setValue("Bearer \(MDAuthentification.standard.getSessionToken())", forHTTPHeaderField: "Authorization")
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    struct Response: Decodable {
                        let data: [String]?
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
                    
                    let chaptersReadCount = (decodedResponse.data ?? []).count
                    var counter: Int = 0
                    
                    var tempArray = self.chapters
                    for (index, chapter) in tempArray.enumerated() {
                        for id in ( decodedResponse.data ?? [] ) {
                            if ( chapter.chapterId == id ) {
                                tempArray[index].isRead = true
                                counter += 1
                                break
                            }
                        }
                        
                        if ( chaptersReadCount == counter ) {
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.chapters = tempArray
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                } catch {
                    print(error)
                    
                    DispatchQueue.main.async {
                        appState.errorMessage += "From Manga (read marker loading).\nAn error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n URL: \(url.absoluteString)\n Data received from server: \(String(describing: String(data: data, encoding: .utf8)))\n\n\n"
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
    //MARK: - Update the reading status of the manga
    func updateMangaStatus(statusId: Int) {
        let loadingDescription: LocalizedStringKey = "Updating status..."
        
        guard let url = URL(string :"\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")manga/\(mangaId)/status") else {
            print("from updateMangaStatus: Invalid URL")
            return
        }
        
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
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
                                if ( MangaStatus.allCases[statusId].rawValue == "Unfollow" ) {
                                    currentStatus = "Status"
                                } else {
                                    currentStatus = MangaStatus.allCases[statusId].rawValue
                                }
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
        
        guard let url = URL(string :"\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "( ͡° ͜ʖ ͡°)")manga/\(mangaId)/status") else {
            print("from updateMangaStatus: Invalid URL")
            return
        }
        
        DispatchQueue.main.async {
            appState.loadingQueue.append(loadingDescription)
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
                            if ( key.rawValue == "Unfollow" ) {
                                newStatus = "Status"
                            } else {
                                newStatus = key.rawValue
                            }
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
}

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        MangaView(reloadContents: false, mangaId: "1")
    }
}
