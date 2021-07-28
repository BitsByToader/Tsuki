//
//  ScrollReader.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 11.11.2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct ScrollReader: View {
    @Binding var readerSettingsPresented: Bool
    @Binding var readerStyle: String
    @Binding var navBarHidden: Bool
    
    var pages: [String]
    var contentIsRemote: Bool
    @Binding var currentPage: Int
    @Binding var currentPageBackup: Int
    @Binding var currentChapter: Int
    var remainingChapters: Int
    
    let loadChapter: (Int) -> Void
    
    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                LazyVStack {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        SwipeReaderImage(contentIsRemote: contentIsRemote, imageURL: page)
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
                }.onChange(of: readerSettingsPresented) { newValue in
                    if !readerSettingsPresented && readerStyle == "Scroll" {
                        withAnimation {
                            value.scrollTo(currentPageBackup, anchor: .top)
                        }
                    }
                }.onChange(of: navBarHidden) { _ in
                    withAnimation {
                        value.scrollTo(currentPage, anchor: .top)
                    }
                }
            }
        }
    }
}
