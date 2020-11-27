//
//  SwipeReaderTest.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 27.11.2020.
//

import SwiftUI
import SDWebImageSwiftUI

//A good alternative to the UIKit UIPageViewController embedded inside of a UIViewControllerRepresentable
//Only two problems:
// -very slow. It is so laggy to swipe between images
// -very limited in customizations
//I'll wait and see how Apple improves this, as it has potential

struct SwipeReaderTest: View {
    @Binding var pages: [String]
    
    var contentIsRemote: Bool
    @Binding var currentPage: Int
    @Binding var currentChapter: Int
    var remainingChapters: Int
    
    let loadChapter: (Int) -> Void
    
    var body: some View {
        TabView {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                
//                Spacer()
                ScrollView {
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
                
                
                
//                Spacer()
            }
        }.tabViewStyle(PageTabViewStyle())
    }
}
