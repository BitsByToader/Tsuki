
//  DownloadedManga+CoreDataProperties.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 03/09/2020.
//
//

import Foundation
import CoreData


extension DownloadedManga {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadedManga> {
        return NSFetchRequest<DownloadedManga>(entityName: "DownloadedManga")
    }

    @NSManaged public var mangaArtist: String?
    @NSManaged public var mangaCoverURL: String?
    @NSManaged public var mangaDescription: String?
    @NSManaged public var mangaId: UUID?
    @NSManaged public var mangaRating: String?
    @NSManaged public var mangaTags: [String]?
    @NSManaged public var mangaTitle: String?
    @NSManaged public var usersRated: String?
    @NSManaged public var chapter: NSSet?
    
    public var wrappedMangaArtist: String {
        mangaArtist ?? "Unknown artist"
    }
    
    public var wrappedMangaCoverURL: String {
        mangaCoverURL ?? "No cover"
    }
    
    public var wrappedMangaDescription: String {
        mangaDescription ?? "Unknown description"
    }
    
    public var wrappedMangaId: UUID {
        mangaId ?? UUID()
    }
    
    public var wrappedMangaRating: String {
        mangaRating ?? "0"
    }
    
    public var wrappedMangaTags: [String] {
        mangaTags ?? []
    }
    
    public var wrappedMangaTitle: String {
        mangaTitle ?? "Unknown title"
    }
    
    public var wrappedUsersRated: String {
        usersRated ?? "0"
    }
    
    public var chapterArray: [DownloadedChapter] {
        let set = chapter as? Set<DownloadedChapter> ?? []
        
        return set.sorted {
            //Same story for sorting as in MangaView.swift
            return Double( ($0.chapter?.split(separator: " ")[0])! )! < Double( ($1.chapter?.split(separator: " ")[0])! )!
        }
    }

}

// MARK: Generated accessors for chapter
extension DownloadedManga {

    @objc(addChapterObject:)
    @NSManaged public func addToChapter(_ value: DownloadedChapter)

    @objc(removeChapterObject:)
    @NSManaged public func removeFromChapter(_ value: DownloadedChapter)

    @objc(addChapter:)
    @NSManaged public func addToChapter(_ values: NSSet)

    @objc(removeChapter:)
    @NSManaged public func removeFromChapter(_ values: NSSet)

}

extension DownloadedManga : Identifiable {

}
