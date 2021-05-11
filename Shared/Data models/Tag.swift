//
//  Tag.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 24/07/2020.
//

import Foundation
import SwiftUI

//MARK: - Global MangaTags class
class MangaTags: ObservableObject  {
    @Published var tags: [String: String] = [:]
    
    func loadTags(completion: @escaping ([String: String]) -> Void) {
        //let loadingDescription: LocalizedStringKey = "Loading search tags..."
        //appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "https://api.mangadex.org/manga/tag") else {
            print("From SearchView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From SearchView: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode([MDTag].self, from: data)
                    
                    var MDTags: [String: String] = [:]
                    
                    for tag in decodedResponse {
                        MDTags[tag.id] = tag.name
                    }
                    
                    DispatchQueue.main.async {
                        self.tags = MDTags
                        completion(self.tags)
                        //self.appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
}

//MARK: - Tag struct (used in the UI)
struct Tag: Hashable {
    let tagName: String
    let id: String
    var state: ToggleState = .untoggled
    
    enum ToggleState {
        case enabled
        case disabled
        case untoggled
    }
    
    init(from decodedTag: MDTag) {
        self.tagName = decodedTag.name
        self.id = decodedTag.id
    }
    
    init(id: String, tagName: String) {
        self.id = id
        self.tagName = tagName
    }
}

//MARK: - Tag struct (used in the response)
struct MDTag: Decodable {
    let id: String
    let name: String
    
    //MARK: Decodable stuff...
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    enum DataCodingKeys: String, CodingKey {
        case id, attributes
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case name
    }
    
    enum NameCodingKeys: String, CodingKey {
        case en
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        id = try data.decode(String.self, forKey: .id)
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        let nameContainer = try attributes.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
        name = try nameContainer.decode(String.self, forKey: .en)
    }
}
