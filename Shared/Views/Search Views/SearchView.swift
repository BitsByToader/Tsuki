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

struct SearchView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var mangaTags: MangaTags
    @Environment(\.colorScheme) var colorScheme
    
    @State private var searchInput: String = ""
    @State private var showCancelButton: Bool = false
    @State private var logInViewPresented: Bool = false
    
    @State private var tagsDict: [String: [Tag]] = [:]
    
    @State private var includedTagsArray: [String] = []
    @State private var excludedTagsArray: [String] = []
    
    #warning("Refactor this to use the ToggleState enum from the Tag struct")
    enum TagMode {
        case include, exclude
    }
    
    var body: some View {
            NavigationView {
                ZStack(alignment: .bottom) {
                    List {
                        Section() {
                            NavigationLink(destination: SearchByNameView()) {
                                Text("Search by name")
                            }
                        }
                        
                        ForEach(Array(tagsDict.keys.sorted(by: >)), id:\.self) { section in
                            Section(header: Text(section)) {
                                ForEach(Array((tagsDict[section] ?? []).enumerated()), id: \.element) { i, tag in
                                    Button(action: {
                                        switch tag.state {
                                        case .untoggled:
                                            //If the row is untoggled, we'll include the tag.
                                            withAnimation {
                                                tagsDict[section]?[i].state = .enabled
                                                updateTagArray(mode: .include, tagId: tag.id)
                                            }
                                        case .enabled:
                                            //If the row is included, we'll exclude it
                                            withAnimation {
                                                tagsDict[section]?[i].state = .disabled
                                                removeTagFromArray(mode: .include, tagId: tag.id)
                                                updateTagArray(mode: .exclude, tagId: tag.id)
                                            }
                                        case .disabled:
                                            //If the row is excluded, we'll untoggle it.
                                            withAnimation {
                                                tagsDict[section]?[i].state = .untoggled
                                                removeTagFromArray(mode: .exclude, tagId: tag.id)
                                            }
                                        }
                                    }, label: {
                                        Text(tag.tagName)
                                            .foregroundColor( (colorScheme == .dark) || (tag.state == .enabled || tag.state == .disabled) ? .white : .black)
                                    }).listRowBackground(state: tag.state)
                                }
                            }
                        }
                    }.navigationBarTitle(Text("Search"))
                    .listStyle(InsetGroupedListStyle())
                    
                    if includedTagsArray.count > 0 || excludedTagsArray.count > 0 {
                        NavigationLink(destination: SearchByNameView(includedTagsToSearch: includedTagsArray, excludedTagsToSearch: excludedTagsArray, preloadManga: true)) {
                            SearchWithTagsBox(includedTags: includedTagsArray.count, excludedTags: excludedTagsArray.count)
                        }.transition(.move(edge: .bottom))
                    }
                }
                
                
                MangaView(reloadContents: true, mangaId: "d1c0d3f9-f359-467c-8474-0b2ea8e06f3d") //30461

                ChapterView(loadContents: true, isViewPresented: .constant(1),remainingChapters: [])//449711
                
            }.if( sizeClass == .regular ) { $0.navigationViewStyle(DoubleColumnNavigationViewStyle()) }
            .if ( sizeClass == .compact ) { $0.navigationViewStyle(StackNavigationViewStyle()) }
            .onAppear {
                if mangaTags.tags.isEmpty {
                    if UserDefaults.standard.value(forKey: "apiURL") == nil {
                        return
                    }
                    
                    let loadingDescription: LocalizedStringKey = "Loading search tags..."
                    appState.loadingQueue.append(loadingDescription)
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        mangaTags.loadTags { testDict in
                            DispatchQueue.main.async {
                                self.tagsDict = testDict
                                appState.removeFromLoadingQueue(loadingState: loadingDescription)
                            }
                        }
                    }
                }
            }
    }
    
    #warning("Maybe refactor these two functions into one and place them in the tag struct or smth")
    func updateTagArray(mode: TagMode, tagId: String) {
        switch mode {
        case .include:
            includedTagsArray.append(tagId)
        case .exclude:
            excludedTagsArray.append(tagId)
        }
    }
    
    func removeTagFromArray(mode: TagMode, tagId: String) {
        switch mode {
        case .include:
            includedTagsArray = includedTagsArray.filter { $0 != tagId }
        case .exclude:
            excludedTagsArray = excludedTagsArray.filter { $0 != tagId }
        }
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
                        .bold()
                    Text("Tags: " + (includedTags > 0 ? "\(includedTags) included" : "") + (excludedTags > 0 && includedTags > 0 ? ", " : "") + (excludedTags > 0 ? "\(excludedTags) excluded" : "") )
                        .opacity(0.5)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }.padding(.horizontal)
        }.frame(height: 60)
        .padding()
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
