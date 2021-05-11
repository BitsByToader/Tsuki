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
    
    @State private var tags: [Tag] = []
    
    @State private var includedTagsArray: [String] = []
    @State private var excludedTagsArray: [String] = []
    @State private var includedTags: Int = 0
    @State private var excludedTags: Int = 0
    
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
                        
                        Section(header: Text("Tags")) {
                            ForEach(Array((tags).enumerated()), id: \.element) { i, tag in
                                Button(action: {
                                    switch tag.state {
                                    case .untoggled:
                                        //If the row is untoggled, we'll include the tag.
                                        withAnimation {
                                            tags[i].state = .enabled
                                            updateTagArray(mode: .include, tagId: tag.id)
//                                            includedTags += 1
                                        }
                                    case .enabled:
                                        //If the row is included, we'll exclude it
                                        withAnimation {
                                            tags[i].state = .disabled
                                            removeTagFromArray(mode: .include, tagId: tag.id)
                                            updateTagArray(mode: .exclude, tagId: tag.id)
//                                            includedTags -= 1
//                                            excludedTags += 1
                                        }
                                    case .disabled:
                                        //If the row is excluded, we'll untoggle it.
                                        withAnimation {
                                            tags[i].state = .untoggled
                                            removeTagFromArray(mode: .exclude, tagId: tag.id)
//                                            excludedTags -= 1
                                        }
                                    }
                                }, label: {
                                    Text(tag.tagName)
                                        .foregroundColor( (colorScheme == .dark) || (tag.state == .enabled || tag.state == .disabled) ? .white : .black)
                                }).listRowBackground(state: tag.state)
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
                
                
                MangaView(reloadContents: true, mangaId: "30461") //30461

                ChapterView(loadContents: true, isViewPresented: .constant(1),remainingChapters: [])//449711
                
            }.if( sizeClass == .regular ) { $0.navigationViewStyle(DoubleColumnNavigationViewStyle()) }
            .if ( sizeClass == .compact ) { $0.navigationViewStyle(StackNavigationViewStyle()) }
            .onAppear {
                if mangaTags.tags.isEmpty {
                    let loadingDescription: LocalizedStringKey = "Loading search tags..."
                    appState.loadingQueue.append(loadingDescription)
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        mangaTags.loadTags { tagsDict in
                            var arr: [Tag] = []
                            
                            for (id, name) in tagsDict {
                                arr.append(Tag(id: id, tagName: name))
                            }
                            
                            arr = arr.sorted {
                                return $0.tagName < $1.tagName
                            }
                            
                            DispatchQueue.main.async {
                                self.tags = arr
                                appState.removeFromLoadingQueue(loadingState: loadingDescription)
                            }
                        }
                    }
                }
            }
    }
    
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
