//
//  UpdatedMangas.swift
//  LatestUpdatesWidgetExtension
//
//  Created by Tudor Ifrim on 11/09/2020.
//

import Foundation
import WidgetKit

struct UpdatedMangas {
    let mangas: [UpdatedManga]
    let placeholder: Bool
    let relevance: Int
    
    init(mangas: [UpdatedManga], placeholder: Bool, relevance: Int) {
        self.mangas = mangas
        self.placeholder = placeholder
        self.relevance = relevance
    }
    
    static func getLibraryUpdates(completion: @escaping (UpdatedMangas?, String?) -> Void) {
        guard let url = URL(string: "https://mangadex.org") else {
            print("From chapter selection view, invalid url")
            
            completion(nil, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        //Get the login cookies from the shared container with the main app
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpCookieStorage = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "group.TsukiApp")
        let session = URLSession(configuration: sessionConfig)
        
        if ( (HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "group.TsukiApp").cookies ?? []).isEmpty ) {
            completion(nil, "You need to login before viewing the library updates.")
        }
        
        session.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    /*let doc: Document = try SwiftSoup.parse(String(data: data, encoding: .utf8)!)
                    
                    let returnedMangas = try doc.getElementById("follows_update")?.child(0).children().array()
                    
                    let numberOfMangas: Int = (returnedMangas ?? []).count >= 6 ? 6 : (returnedMangas ?? []).count
                    
                    print(numberOfMangas)
                    
                    var mangas: [UpdatedManga] = []
                    var mangaIds: [String] = []
                    
                    for index in 0 ..< numberOfMangas {
                        let title: String = "try (returnedMangas ?? [])[index].child(1).getElementsByClass("manga_title").first()!.text()"
                        let coverArt: String = "try (returnedMangas ?? [])[index].getElementsByClass("sm_md_logo").first()!.select("a").select("img").attr("src")"
                        
                        let mangaLink: String = "try (returnedMangas ?? [])[index].child(1).getElementsByClass("manga_title").first()!.attr("href")"
                        let mangaId: String = mangaLink.components(separatedBy: "/")[2]
                        
                        mangas.append(UpdatedManga(title: title, cover: coverArt, id: mangaId))
                        mangaIds.append(mangaId)
                    }
                    
                    var similarCounter: Int = 0
                    let array: [String] = UserDefaults.standard.stringArray(forKey: "latestMangas") ?? []
                    for id in array {
                        for anotherId in mangaIds {
                            if ( id == anotherId ) {
                                similarCounter += 1
                                break
                            }
                        }
                    }
                    
                    let relevance = array.count - similarCounter
                    print(relevance)
                    UserDefaults.standard.setValue(mangaIds, forKey: "latestMangas")
                    
                    for _ in mangas.count ..< 6 {
                        mangas.append(UpdatedManga(title: "", cover: "", id: "", isPlaceholder: true))
                    }
                    */
                    completion(UpdatedMangas(mangas: [], placeholder: false, relevance: 0), nil)
                } catch {
                    completion(nil, error.localizedDescription)
                }
            } else {
                completion(nil, "There was an error retrieving the library.")
            }
        }.resume()
    }
    
    init(numberOfPlaceholder: Int) {
        var array: [UpdatedManga] = []
        for _ in 0..<numberOfPlaceholder {
            array.append(UpdatedManga(title: "", cover: "", id: ""))
        }
        
        self.mangas = array
        self.placeholder = true
        self.relevance = 0
    }
    
    struct UpdatedManga: Hashable {
        let title: String
        let cover: String
        let id: String
        var isPlaceholder: Bool = false
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
