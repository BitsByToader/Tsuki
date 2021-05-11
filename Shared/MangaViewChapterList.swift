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
    let chapters: [Chapter]
    let remote: Bool
    var localChapters: [DownloadedChapter] = []
    
    var formatterToString: DateFormatter {
        let obj: DateFormatter = DateFormatter()
        obj.dateStyle = .medium
        
        return obj
    }
    
    var formatterFromString = ISO8601DateFormatter()
    
    var body: some View {
        List {
            if remote {
                ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                    NavigationLink(destination: ChapterView(loadContents: true, isViewPresented: $navigationSelection, remainingChapters: chapters.reversed().suffix(index+1)), tag: index, selection: $navigationSelection ) {
                        ChapterListRow(volume: chapter.volume,
                                       chapter: chapter.chapter,
                                       title: chapter.title,
                                       date: "\(formatterToString.string(from: formatterFromString.date(from: chapter.timestamp) ?? Date() ))",
                                       localizedTime: (formatterFromString.date(from: chapter.timestamp) ?? Date()).timeAgoDisplay(style: .full) )
                    }
                }
            } else {
                ForEach(Array(localChapters.enumerated()), id: \.offset) { index, chapter in
                    NavigationLink(destination: ChapterView(loadContents: false, isViewPresented: $navigationSelection, remainingChapters: [], remainingLocalChapters: localChapters.reversed().suffix(index+1))) {
                        ChapterListRow(volume: chapter.wrappedVolume,
                                       chapter: chapter.wrappedChapter,
                                       title: chapter.wrappedTitle,
                                       date: "Downloaded",
                                       localizedTime: "\(formatterToString.string(from: formatterFromString.date(from: chapter.timestamp) ?? Date() ))")
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
