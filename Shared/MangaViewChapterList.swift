//
//  MangaViewChapterList.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 25/08/2020.
//

import SwiftUI

struct MangaViewChapterList: View {
    //MARK: - Environment variables
    @Environment(\.managedObjectContext) var moc
    //MARK: - Variables
    @State var navigationSelection: Int? = nil
    let chapters: [Chapter]
    let remote: Bool
    var localChapters: [DownloadedChapter]
    
    let reachedTheBottom: () -> Void
    
    var formatterToString: DateFormatter {
        let obj: DateFormatter = DateFormatter()
        obj.dateStyle = .medium
        
        return obj
    }
    
    var formatterFromString = ISO8601DateFormatter()
    //MARK: - Initializers
    init(localChapters: [DownloadedChapter]) {
        self.localChapters = localChapters
        self.remote = false
        self.chapters = []
        self.reachedTheBottom = {}
    }
    
    init(remoteChapters: [Chapter], reachedTheBottom: @escaping () -> Void) {
        self.chapters = remoteChapters
        self.remote = true
        self.localChapters = []
        self.reachedTheBottom = reachedTheBottom
    }
    //MARK: - SwiftUI Views
    var body: some View {
        List {
            if remote {
                ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                    NavigationLink(destination: ChapterView(loadContents: true, isViewPresented: $navigationSelection, remainingChapters: chapters.reversed().suffix(index+1)), tag: index, selection: $navigationSelection ) {
                        ChapterListRow(volume: chapter.volume,
                                       chapter: chapter.chapter,
                                       title: chapter.title,
                                       languageEmoji: languagesEmojiDict[chapter.chapterLanguageCode] ?? "",
                                       date: "\(formatterToString.string(from: formatterFromString.date(from: chapter.timestamp) ?? Date() ))",
                                       localizedTime: (formatterFromString.date(from: chapter.timestamp) ?? Date()).timeAgoDisplay(style: .full),
                                       isRead: chapter.isRead)
                            .onAppear {
                                if ( index + 1 == chapters.count ) {
                                    reachedTheBottom()
                                }
                            }
                    }
                }
            } else {
                //languageEmoji will be an empty string for local chapters because it is already inserted in the chapter string
                ForEach(Array(localChapters.enumerated()), id: \.offset) { index, chapter in
                    NavigationLink(destination: ChapterView(loadContents: false, isViewPresented: $navigationSelection, remainingChapters: [], remainingLocalChapters: localChapters.reversed().suffix(index+1))) {
                        ChapterListRow(volume: chapter.wrappedVolume,
                                       chapter: chapter.wrappedChapter,
                                       title: chapter.wrappedTitle,
                                       languageEmoji: "",
                                       date: "Downloaded",
                                       localizedTime: "\(formatterToString.string(from: formatterFromString.date(from: chapter.timestamp) ?? Date() ))",
                                       isRead: false)
                    }
                }
            }
            
        }.frame(height: 200)
    }
}
//MARK: - ChaptereListRow Struct
struct ChapterListRow: View {
    let volume: String
    let chapter: String
    let title: String
    let languageEmoji: String
    
    let date: String
    let localizedTime: String
    
    let isRead: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Vol.\(volume) Ch.\(chapter) \(languageEmoji)")
                    .font(.subheadline)
                
                Image(systemName: "checkmark")
                    .opacity(isRead ? 0.5 : 0)
                    .animation(.default)
                
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
