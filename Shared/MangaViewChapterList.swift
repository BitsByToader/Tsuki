//
//  MangaViewChapterList.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 25/08/2020.
//

import SwiftUI

struct MangaViewChapterList: View {
    let chapters: [Chapter]
    
    var body: some View {
        List {
            ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                NavigationLink(destination: ChapterView(remainingChapters: chapters.reversed().suffix(index+1))) {
                    HStack {
                        Text("Vol.\(chapter.chapterInfo.volume!) Ch.\(chapter.chapterInfo.chapter!)")
                            .font(.subheadline)
                        Spacer()
                        Text("\(chapter.chapterInfo.title!)")
                            .allowsTightening(true)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .opacity(0.5)
                    }
                }
            }
        }.frame(height: 200)
    }
}

//struct MangaViewChapterList_Previews: PreviewProvider {
//    static var previews: some View {
//        MangaViewChapterList()
//    }
//}
