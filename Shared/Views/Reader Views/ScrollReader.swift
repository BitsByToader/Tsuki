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
        ScrollViewReader { value in
            ScrollView {
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
                                    
                                    if ( currentPage + 2 == pages.count && currentChapter + 1 != remainingChapters ) {
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
            }.onChange(of: readerStyle) { _ in
                print("style changed")
                withAnimation {
                    value.scrollTo(currentPage, anchor: .top)
                }
            }.onChange(of: navBarHidden) { _ in
                withAnimation {
                    value.scrollTo(currentPage, anchor: .top)
                }
            }
        }
    }
}
