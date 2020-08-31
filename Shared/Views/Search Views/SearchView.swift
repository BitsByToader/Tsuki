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
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var mangaTags: MangaTags
    @Environment(\.colorScheme) var colorScheme
    
    private var loggedIn: Bool {
        checkLogInStatus()
    }
    
    @State private var searchInput: String = ""
    @State private var showCancelButton: Bool = false
    @State private var logInViewPresented: Bool = false
    
    @State private var sectionList: [TagSection] = []
    
    @State private var tagString: String = ""
    @State private var includedTags: Int = 0
    @State private var excludedTags: Int = 0
    
    var body: some View {
        if loggedIn {
            NavigationView {
                ZStack(alignment: .bottom) {
                    List {
                        // Filtered list of names
                        Section() {
                            NavigationLink(destination: SearchByNameView()) {
                                Text("Search by name")
                            }
                        }
                        
                        ForEach(Array(sectionList.enumerated()), id: \.element) { i, section in
                            Section(header: Text(section.sectionName)) {
                                ForEach(Array((section.tags).enumerated()), id: \.element) { j, tag in
                                    Button(action: {
                                        switch tag.state {
                                        case .untoggled:
                                            withAnimation {
                                                sectionList[i].tags[j].state = .enabled
                                                updateTagString(tagId: tag.id)
                                                includedTags += 1
                                            }
                                        case .enabled:
                                            withAnimation {
                                                sectionList[i].tags[j].state = .disabled
                                                updateTagString(tagId: "-\(tag.id)")
                                                includedTags -= 1
                                                excludedTags += 1
                                            }
                                        case .disabled:
                                            withAnimation {
                                                sectionList[i].tags[j].state = .untoggled
                                                removeTagFromString(tagId: "-\(tag.id)")
                                                excludedTags -= 1
                                            }
                                        }
                                    }, label: {
                                        Text(tag.tagName)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }).listRowBackground(state: tag.state)
                                }
                            }
                        }
                        
                    }.navigationBarTitle(Text("Search"))
                    .listStyle(InsetGroupedListStyle())
                    
                    if includedTags > 0 || excludedTags > 0 {
                        NavigationLink(destination: SearchByNameView(tagsToSearch: tagString, preloadManga: true)) {
                            SearchWithTagsBox(includedTags: includedTags, excludedTags: excludedTags)
                        }.transition(.move(edge: .bottom))
                    }
                }
                
                if sizeClass == .regular {
                    MangaView(reloadContents: false, mangaId: "")
                    
                    ChapterView(loadContents: false, remainingChapters: [Chapter(chapterId: "", chapterInfo: ChapterData(volume: "", chapter: "", title: "", langCode: "", timestamp: 0))])
                }
            }.navigationViewStyle(DoubleColumnNavigationViewStyle())
            .onAppear {
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
        
        mangaTags.tags = []
        
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
                            appState.isLoading = false
                        }
                    }
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Unknown error when parsing response from server.\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.isLoading = false
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                    appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                    withAnimation {
                        appState.errorOccured = true
                        appState.isLoading = false
                    }
                }
            }
        }.resume()
    }
    
    func updateTagString(tagId: String) {
        var tagsArray: [String] = tagString.components(separatedBy: ",")
        if ( tagString == "" ) {
            tagsArray = []
        }
        
        var newString: String = ""
        for tag in tagsArray {
            if ( tagId != tag && String(tagId.dropFirst()) != tag && tagId != "-\(tag)" ) {
                //If the tag is alreay in the array(included or excluded), ignore it
                newString += "\(tag),"
            }
        }
        //Add it at the end with the updated state (included/excluded)
        newString += "\(tagId)"
        
        //Update the string
        self.tagString = newString
    }
    
    func removeTagFromString(tagId: String) {
        let tagsArray: [String] = tagString.components(separatedBy: ",")
        
        var newString: String = ""
        for tag in tagsArray {
            if ( tag != tagId ) {
                newString += "\(tag),"
            }
        }
        
        self.tagString = String(newString.dropLast())
    }
}

struct SearchWithTagsBox: View {
    var includedTags: Int
    var excludedTags: Int
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.accentColor)
                .cornerRadius(10)
            
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Search with current tags")
                    Text("Tags: " + (includedTags > 0 ? "\(includedTags) included" : "") + (excludedTags > 0 && includedTags > 0 ? ", " : "") + (excludedTags > 0 ? "\(excludedTags) excluded" : "") )
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }.padding(.horizontal, 10)
        }.frame(height: 60)
        .padding(5)
        .foregroundColor(.white)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}

extension View {
    func listRowBackground(state: Tag.ToggleState) -> some View {
        switch state {
        case .disabled:
            return self.listRowBackground(Color.red)
                .animation(.default)
        case .enabled:
            return self.listRowBackground(Color.green)
                .animation(.default)
        case .untoggled:
            return self.listRowBackground(Color.clear)
                .animation(.default)
        }
    }
}
