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
    @Published var tags: [String: [Tag]] = [:]
    
    func loadTags(completion: @escaping ([String: [Tag]]) -> Void) {
        //let loadingDescription: LocalizedStringKey = "Loading search tags..."
        //appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "\(UserDefaults.standard.value(forKey: "apiURL") ?? "")manga/tag") else {
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
                    
                    var tagDict: [String: [Tag]] = [:]
                    for tag in decodedResponse {
                        if tagDict.index(forKey: tag.group) == nil {
                            //The tag group wasn't added to the dictionary yet
                            tagDict[tag.group] = [Tag(id: tag.id, tagName: tag.name)]
                        } else {
                            //The tag group is in the dictionery so update the array for that group
                            var tempArr = tagDict[tag.group]
                            tempArr?.append(Tag(id: tag.id, tagName: tag.name))
                            
                            tagDict[tag.group] = tempArr
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.tags = tagDict
                        completion(tagDict)
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
    let group: String
    
    //MARK: Decodable stuff...
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    enum DataCodingKeys: String, CodingKey {
        case id, attributes
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case name, group
    }
    
    enum NameCodingKeys: String, CodingKey {
        case en
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        self.id = try data.decode(String.self, forKey: .id)
        let attributes = try data.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
        
        self.group = try attributes.decode(String.self, forKey: .group)
        let nameContainer = try attributes.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
        self.name = try nameContainer.decode(String.self, forKey: .en)
    }
}
