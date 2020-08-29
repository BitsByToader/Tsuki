//
//  SearchView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 22/07/2020.
//

/*
 I am not a huge fan of this navigation layout but I can't get a
 *proper looking* search bar to work on a list. Basically, the navBar
 breaks horribly (it won't shrink, and it will have a white background,
 while the list has its usual grey) if i put a textfield in the same view as a list.
 */

import SwiftUI
import SwiftSoup

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var mangaTags: MangaTags
    
    private var loggedIn: Bool {
        checkLogInStatus()
    }
    
    @State private var searchInput: String = ""
    @State private var showCancelButton: Bool = false
    @State private var logInViewPresented: Bool = false
    
    @State private var sectionList: [TagSection] = []
    
    var body: some View {
        if loggedIn {
            NavigationView {
                List {
                    // Filtered list of names
                    Section() {
                        NavigationLink(destination: SearchByNameView()) {
                            Text("Search by name")
                        }
                    }
                    
                    ForEach(sectionList, id: \.self) { section in
                        Section(header: Text(section.sectionName)) {
                            ForEach(section.tags, id: \.self) { tag in
                                NavigationLink(destination: SearchByNameView(tagsToSearch: tag.id, preloadManga: true, sectionName: tag.tagName)) {
                                    Text(tag.tagName)
                                }
                            }
                        }
                    }
                    
                }.transition(.fade)
                .navigationBarTitle(Text("Search"))
                .listStyle(InsetGroupedListStyle())
            }.onAppear {
                if (loggedIn) {
                    appState.isLoading = true
                    retrieveTags()
                }
            }
        } else {
            SignInRequiredView(description: "The search function will be available once you sign in.", logInViewPresented: $logInViewPresented)
        }
    }
    
    func retrieveTags() {
        guard let url = URL(string: "https://mangadex.org/search") else {
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
                    
                    let doc: Document = try SwiftSoup.parse(String(data: data, encoding: .utf8)!)
                    
                    let tagForm = try doc.getElementsByClass("chip-input").first()
                    let sections = try tagForm?.select("optgroup").array()
                    var extractedSections: [TagSection] = []
                    
                    for section in sections ?? [] {
                        let tags = try section.select("option").array()
                        
                        var extractedTags: [Tag] = []
                        for tag in tags {
                            try extractedTags.append(Tag(tagName: tag.text(), id: tag.attr("value")))
                        }
                        
                        try extractedSections.append(TagSection(tags: extractedTags, sectionName: section.attr("label")))
                        mangaTags.tags += extractedTags
                    }
                    
                    DispatchQueue.main.async {
                        sectionList = extractedSections
                        appState.isLoading = false
                    }
                    
                    return
                } catch Exception.Error(let type, let message) {
                    print ("Error of type \(type): \(message)")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Error when parsing response from server. \nType: \(type) \nMessage: \(message)\n\n"
                        withAnimation {
                            appState.errorOccured = true
                        }
                    }
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Unknown error when parsing response from server.\n\n"
                        withAnimation {
                            appState.errorOccured = true
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                    }
                }
            }
        }.resume()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
