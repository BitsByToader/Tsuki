//
//  ScrollReader.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 11.11.2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct ScrollReader: View {
    @Binding var readerStyle: String
    @Binding var navBarHidden: Bool
    
    var pages: [String]
    var contentIsRemote: Bool
    @Binding var currentPage: Int
    @Binding var currentChapter: Int
    var remainingChapters: Int
    
    let loadChapter: (Int) -> Void
    
    var body: some View {
        ScrollView {
                ScrollViewReader { value in
                    Rectangle()
                        .frame(width: 0, height: 0)
//                        .onChange(of: readerStyle) { newValue in
//                            withAnimation {
//                                value.scrollTo(currentPage)
//                            }
//                        }.onChange(of: navBarHidden) { newValue in
//                            print("wow such change")
//                                value.scrollTo(currentPage)
//                            
//                        }
                    
                    LazyVStack {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            if contentIsRemote {
                                WebImage(url: URL(string: page))
                                    .resizable()
                                    .placeholder {
                                        Rectangle().foregroundColor(.gray)
                                            .opacity(0.2)
                                    }
                                    .indicator(.activity)
                                    .transition(.fade(duration: 0.5))
                                    .scaledToFit()
                                    .id(index)
                                    .onAppear {
                                        currentPage = index
                                        
                                        if ( currentPage + 2 == pages.count && currentChapter + 1 != remainingChapters ) { //(contentIsRemote ? remainingChapters.count : remainingLocalChapters.count)
                                            currentChapter += 1
                                            loadChapter(currentChapter)
                                            
                                            let hapticFeedback = UIImpactFeedbackGenerator(style: .soft)
                                            hapticFeedback.impactOccurred()
                                        }
                                    }
                            } else {
                                Image(uiImage: UIImage(contentsOfFile: page)!)
                                    .resizable()
                                    .transition(.fade(duration:0.5))
                                    .scaledToFit()
                                    .id(index)
                                    .onAppear {
                                        currentPage = index
                                        
                                        if ( currentPage + 2 == pages.count && currentChapter + 1 != remainingChapters ) {
                                            currentChapter += 1
                                            loadChapter(currentChapter)
                                            
                                            let hapticFeedback = UIImpactFeedbackGenerator(style: .soft)
                                            hapticFeedback.impactOccurred()
                                        }
                                    }
                            }
                    }
                }
            }
        }
    }
}
