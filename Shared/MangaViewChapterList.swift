//
//  MangaViewChapterList.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 25/08/2020.
//

import SwiftUI

struct MangaViewChapterList: View {
    @Environment(\.managedObjectContext) var moc
    
    @State var navigationSelection: Int? = nil
    let chapters: [ChapterData]
    let remote: Bool
    var localChapters: [DownloadedChapter] = []
    
    var formatter: DateFormatter {
        let obj: DateFormatter = DateFormatter()
        obj.dateStyle = .medium
        
        return obj
    }
    
    var chapterTimeStamps: [String] {
        var array: [String] = []
        
        for chapter in chapters {
            let timestamp: Double = chapter.timestamp ?? 0
            var timeElapsed: Int = Int( Date().timeIntervalSince1970 - timestamp )
            
            let futureChapter: Bool = timeElapsed < 0
            timeElapsed = futureChapter ? -timeElapsed : timeElapsed
            
            if ( timeElapsed < 60 ) {
                array.append(futureChapter ? "In \(timeElapsed)s" : "\( timeElapsed )s ago")
            } else if ( timeElapsed < 3600 ) { //one hour aka 3600 seconds
                array.append(futureChapter ? "In \( timeElapsed / 60 ) min" : "\( timeElapsed / 60 ) min ago")
            } else if ( timeElapsed < 86400 ) { //one day aka 24 hours
                array.append(futureChapter ? "In \( timeElapsed / 3600 )h" : "\( timeElapsed / 3600 )h ago")
            } else if ( timeElapsed < 2592000 ) { //30 days aka 1 month
                array.append(futureChapter ? "In \( timeElapsed / 86400 ) days" : "\( timeElapsed / 86400 ) days ago")
            } else if ( timeElapsed < 31536000 ) { //365 days aka 12 months aka 1 year
                array.append(futureChapter ? "In \( timeElapsed / 2592000 ) mo" : "\( timeElapsed / 2592000 ) mo ago")
            } else {
                array.append(futureChapter ? "In \( timeElapsed / 31536000 ) yrs" : "\( timeElapsed / 31536000 ) yrs ago")
            }
        }
        
        return array
    }
    
    var body: some View {
        List {
            if remote {
                ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                    NavigationLink(destination: ChapterView(loadContents: true, isViewPresented: $navigationSelection, remainingChapters: chapters.reversed().suffix(index+1)), tag: index, selection: $navigationSelection ) {
                        ChapterListRow(volume: chapter.volume ?? "",
                                       chapter: chapter.chapter,
                                       title: chapter.title!,
                                       date: "\(formatter.string(from: Date(timeIntervalSince1970: chapter.timestamp ?? 0)))",
                                       localizedTime: chapterTimeStamps[index])
                    }
                }
            } else {
                ForEach(Array(localChapters.enumerated()), id: \.offset) { index, chapter in
                    NavigationLink(destination: ChapterView(loadContents: false, isViewPresented: $navigationSelection, remainingChapters: [], remainingLocalChapters: localChapters.reversed().suffix(index+1))) {
                        ChapterListRow(volume: chapter.wrappedVolume,
                                       chapter: chapter.wrappedChapter,
                                       title: chapter.wrappedTitle,
                                       date: "Downloaded",
                                       localizedTime: "\(formatter.string(from: Date(timeIntervalSince1970: chapter.wrappedTimeStamp)))")
                    }
                }
            }
            
        }.frame(height: 200)
    }
}

struct ChapterListRow: View {
    let volume: String
    let chapter: String
    let title: String
    
    let date: String
    let localizedTime: String
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Vol.\(volume) Ch.\(chapter)")
                    .font(.subheadline)
                Spacer()
                Text("\(title)")
                    .allowsTightening(true)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .opacity(0.5)
            }
            
            HStack {
                Text("\(date)")
                    .font(.subheadline)
                    .allowsTightening(true)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .opacity(0.5)
                
                Spacer()
                
                Text("\(localizedTime)")
                    .font(.subheadline)
                    .allowsTightening(true)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .opacity(0.5)
            }
        }
    }
}
