//
//  UpdatedMangas.swift
//  LatestUpdatesWidgetExtension
//
//  Created by Tudor Ifrim on 11/09/2020.
//

import Foundation
import WidgetKit
import SwiftKeychainWrapper

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
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "30"))
        urlComponents.queryItems?.append(URLQueryItem(name: "order[publishAt]", value: "desc"))
        
        let pickedLanguages = UserDefaults(suiteName: "group.TsukiApp")?.stringArray(forKey: "pickedLanguages") ?? []
        
        for lang in pickedLanguages {
            urlComponents.queryItems?.append(URLQueryItem(name: "translatedLanguage[]", value: lang))
        }
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "")user/follows/manga/feed?\(urlComponents.percentEncodedQuery ?? "")") else {
            print("From LatestUpdatesView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(MDAuthentification.standard.getSessionToken())", forHTTPHeaderField: "Authorization")
        
        print("From getLibraryUpdates: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    struct Results: Decodable {
                        let data: [Chapter]
                    }
                 
                    let decodedResponse = try JSONDecoder().decode(Results.self, from: data)
                    
                    var mangas: [UpdatedManga] = []
                    var mangaIds: [String] = []
                    
                    for chapter in decodedResponse.data {
                        if !mangaIds.contains(chapter.mangaId) {
                            mangaIds.append(chapter.mangaId)
                        }
                    }
                    
                    getChapterCovers(mangaIds: mangaIds) { covers in
                        for manga in mangaIds {
                            mangas.append(UpdatedManga(title: covers[manga]?.title ?? "",
                                                       cover: covers[manga]?.coverArtURL ?? "",
                                                       id: manga,
                                                       isPlaceholder: false))
                        }
                        
                        #warning("Place a check if the mangas array is empty to indicate we didn't find any manga")
                        for _ in 0 ..< 6 {
                            mangas.append(UpdatedManga(title: "", cover: "", id: "", isPlaceholder: true))
                        }
                        
                        var similarCounter: Int = 0
                        let array: [String] = UserDefaults(suiteName: "group.TsukiApp")?.stringArray(forKey: "latestMangas") ?? []
                        for id in array {
                            for anotherId in mangaIds {
                                if ( id == anotherId ) {
                                    similarCounter += 1
                                    break
                                }
                            }
                        }
                        
                        let relevance = array.count - similarCounter
                        print("Relevance: \(relevance)")
                        UserDefaults(suiteName: "group.TsukiApp")?.setValue(mangaIds, forKey: "latestMangas")
                        
                        completion(UpdatedMangas(mangas: mangas, placeholder: false, relevance: relevance), nil)
                    }
                } catch {
                    print(error)
                    completion(nil, error.localizedDescription)
                }
            } else {
                print(error ?? "U wot m8?")
                completion(nil, "There was an error retrieving the library.")
            }
        }.resume()
    }
    
    static func getChapterCovers(mangaIds: [String], completion: @escaping([String: ReturnedManga]) -> Void) {
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        
        urlComponents.queryItems?.append(URLQueryItem(name: "limit", value: "30"))
        urlComponents.queryItems?.append(URLQueryItem(name: "includes[]", value: "cover_art"))
        
        for id in mangaIds {
            urlComponents.queryItems?.append(URLQueryItem(name: "ids[]", value: id))
        }
        
        let payload = urlComponents.percentEncodedQuery
        
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "")manga?\(payload ?? "")") else {
            print("From LibraryView: Invalid URL")
            completion([:])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("From getChapterCovers: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(ReturnedMangas.self, from: data)
                    
                    var dict: [String: ReturnedManga] = [:]
                    for manga in decodedResponse.data {
                        dict[manga.id] = manga
                    }
                    
                    completion(dict)
                } catch {
                    completion([:])
                }
            } else {
                completion([:])
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
