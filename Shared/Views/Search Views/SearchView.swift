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
    
    @State private var toggledTags: [Tag] = []
    @State private var includedTagsCount: Int = 0
    @State private var excludedTagsCount: Int = 0
    
    var dragDownGesture: some Gesture {
        DragGesture()
            .onEnded({ value in
                if ( value.startLocation.y < value.location.y ) {
                    resetToggledTags()
                }
            })
    }
    
    var body: some View {
            NavigationView {
                ZStack(alignment: .bottom) {
                    List {
                        Section() {
                            NavigationLink(destination: SearchByNameView(tagsToSearchWith: .constant([]), removeToggledTagByIndex: removeTagByIndex)) {
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
                                            }
                                        case .enabled:
                                            //If the row is included, we'll exclude it
                                            withAnimation {
                                                tagsDict[section]?[i].state = .disabled
                                            }
                                        case .disabled:
                                            //If the row is excluded, we'll untoggle it.
                                            withAnimation {
                                                tagsDict[section]?[i].state = .untoggled
                                            }
                                        }
                                        
                                        if let tagSection = tagsDict[section] {
                                            updateTagArray(tag: tagSection[i])
                                        }
                                    }, label: {
                                        Text(tag.name)
                                            .foregroundColor( (colorScheme == .dark) || (tag.state == .enabled || tag.state == .disabled) ? .white : .black)
                                    }).listRowBackground(state: tag.state)
                                }
                            }
                        }
                    }.navigationBarTitle(Text("Search"))
                    .listStyle(InsetGroupedListStyle())
                    
                    if includedTagsCount > 0 || excludedTagsCount > 0 {
                        NavigationLink(destination: SearchByNameView(tagsToSearchWith: $toggledTags, removeToggledTagByIndex: removeTagByIndex, preloadManga: true)) {
                            SearchWithTagsBox(includedTags: includedTagsCount, excludedTags: excludedTagsCount)
                                .gesture(dragDownGesture)
                                .transition(.move(edge: .bottom))
                        }
                    }
                }
                
                
                MangaView(reloadContents: true, mangaId: "d1c0d3f9-f359-467c-8474-0b2ea8e06f3d") //30461

                ChapterView(loadContents: true, isViewPresented: .constant(1),remainingChapters: [])//449711
                
            }.if( sizeClass == .regular ) { $0.navigationViewStyle(DoubleColumnNavigationViewStyle()) }
            .if ( sizeClass == .compact ) { $0.navigationViewStyle(StackNavigationViewStyle()) }
            .onAppear {
                if mangaTags.tags.isEmpty {
                    if UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") == nil {
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
    
    ///Finds the given tag in the array with its id and updates it.
    ///If it wasn't found, it appends the tag to the array.
    ///Tags with the *.untoggled* `TagState` will be removed from the array.
    func updateTagArray(tag: Tag) {
        var foundTag: Bool = false
        
        for (index, currTag) in toggledTags.enumerated() {
            if ( currTag.id == tag.id ) {
                toggledTags[index] = tag
                foundTag = true
                
                if ( tag.state == .untoggled ) {
                    toggledTags.remove(at: index)
                }
                
                break
            }
        }
        
        if (!foundTag) {
            toggledTags.append(tag)
        }
        
        //This logic applies because the tags will always be updates in the same order
        //i.e. from untoggled, to enabled, to disabled, to untoggled again
        switch tag.state {
        case .enabled:
            includedTagsCount += 1
            
        case .disabled:
            excludedTagsCount += 1
            includedTagsCount -= 1
            
        case .untoggled:
            excludedTagsCount -= 1
        }
    }
    
    ///Resets the toggled tags.
    func resetToggledTags() {
        //Reset the toggle states to update the list
        for section in tagsDict.keys {
            for (index, _) in (tagsDict[section] ?? []).enumerated() {
                tagsDict[section]?[index].state = .untoggled
            }
        }
        
        //Reset the included/excluded counts
        excludedTagsCount = 0
        includedTagsCount = 0
        
        toggledTags.removeAll()
    }
    
    ///Remove the toggle state of the tax using the index of toggledTags array.
    func removeTagByIndex(index: Int) {
        let id: String = toggledTags[index].id
        
        if ( toggledTags[index].state == .enabled ) {
            includedTagsCount -= 1
        } else if ( toggledTags[index].state == .disabled ) {
            excludedTagsCount -= 1
        }
        
        toggledTags.remove(at: index)
        
        for section in tagsDict.keys {
            for (i, tag) in (tagsDict[section] ?? []).enumerated() {
                if ( tag.id == id ) {
                    tagsDict[section]?[i].state = .untoggled
                    return
                }
            }
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
