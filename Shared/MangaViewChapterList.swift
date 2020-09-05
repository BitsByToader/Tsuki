//
//  MangaViewChapterList.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 25/08/2020.
//

import SwiftUI

struct MangaViewChapterList: View {
    let chapters: [Chapter]
    let remote: Bool
    var localChapters: [DownloadedChapter] = []
    
    var body: some View {
        List {
            if remote {
                ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                    NavigationLink(destination: ChapterView(loadContents: true, remainingChapters: chapters.reversed().suffix(index+1))) {
                        HStack {
                            Text("Vol.\(chapter.chapterInfo.volume ?? "") Ch.\(chapter.chapterInfo.chapter )")
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
            } else {
                ForEach(Array(localChapters.enumerated()), id: \.offset) { index, chapter in
                    NavigationLink(destination: ChapterView(loadContents: false, remainingChapters: [], remainingLocalChapters: localChapters.reversed().suffix(index+1))) {
                        HStack {
                            Text("Vol.\(chapter.wrappedVolume) Ch.\(chapter.wrappedChapter )")
                                .font(.subheadline)
                            Spacer()
                            Text("\(chapter.wrappedTitle)")
                                .allowsTightening(true)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .opacity(0.5)
                        }
                    }
                }
            }
            
        }.frame(height: 200)
    }
    
//    func convertChapterArrays(_ chapters : [DownloadedChapter] ) -> [Chapter] {
//        var array: [Chapter] = []
//
//        for chapter in chapters {
//            let info = ChapterData(volume: chapter.wrappedVolume, chapter: chapter.wrappedChapter, title: chapter.wrappedTitle, langCode: "gb", timestamp: chapter.wrappedTimeStamp)
//
//            array += [Chapter(chapterId: "", chapterInfo: info)]
//        }
//
//        return array
//    }
}

//struct MangaViewChapterList_Previews: PreviewProvider {
//    static var previews: some View {
//        MangaViewChapterList()
//    }
//}
