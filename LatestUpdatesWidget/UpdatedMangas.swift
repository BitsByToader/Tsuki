//
//  UpdatedMangas.swift
//  LatestUpdatesWidgetExtension
//
//  Created by Tudor Ifrim on 11/09/2020.
//

import Foundation
import WidgetKit
import SwiftSoup

struct UpdatedMangas {
    let mangas: [UpdatedManga]
    let placeholder: Bool
    
    init?() {
        guard let url = URL(string: "https://mangadex.org") else {
            print("From chapter selection view, invalid url")
            
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        //Get the login cookies from the shared container with the main app
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpCookieStorage = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "group.TsukiApp")
        let session = URLSession(configuration: sessionConfig)
        
        if ( (HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "group.TsukiApp").cookies ?? []).isEmpty ) {
            mangas = []
            placeholder = true
            return nil
        }
        
        let (data, _, error) = session.synchronousDataTask(with: request)
        
        if let error = error {
            print("Big oof \(error)")
            return nil
        } else {
            do {
                let doc: Document = try SwiftSoup.parse(String(data: data!, encoding: .utf8)!)
                
                let returnedMangas = try doc.getElementById("follows_update")?.child(0).children().array()
                
                var mangas: [UpdatedManga] = []
                
                for index in 0..<3 {
                    let title: String = try (returnedMangas ?? [])[index].child(1).getElementsByClass("manga_title").first()!.text()
                    let coverArt: String = try (returnedMangas ?? [])[index].getElementsByClass("sm_md_logo").first()!.select("a").select("img").attr("src")
                    
                    mangas.append(UpdatedManga(title: title, cover: coverArt))
                }
                
                self.mangas = mangas
                self.placeholder = false
            } catch {
                print(error)
                return nil
            }
        }
    }
    
    init(numberOfPlaceholder: Int) {
        var array: [UpdatedManga] = []
        for _ in 0..<numberOfPlaceholder {
            array.append(UpdatedManga(title: "", cover: ""))
        }
        
        self.mangas = array
        self.placeholder = true
    }
    
    struct UpdatedManga: Hashable {
        let title: String
        let cover: String
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
