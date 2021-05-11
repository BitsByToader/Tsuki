//
//  DownloadedChapter+CoreDataProperties.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 03/09/2020.
//
//

import Foundation
import CoreData


extension DownloadedChapter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadedChapter> {
        return NSFetchRequest<DownloadedChapter>(entityName: "DownloadedChapter")
    }

    @NSManaged public var title: String?
    @NSManaged public var timestamp: String
    @NSManaged public var chapter: String?
    @NSManaged public var volume: String
    @NSManaged public var pages: [String]?
    @NSManaged public var origin: DownloadedManga?
    
    public var wrappedTitle: String {
        title ?? "Unknown title"
    }
    
    public var wrappedTimeStamp: String {
        timestamp
    }
    
    public var wrappedChapter: String {
        chapter ?? "Unknown chapter"
    }
    
    public var wrappedVolume: String {
        volume
    }
    
    public var wrappedPages: [String] {
        pages ?? []
    }
}

extension DownloadedChapter : Identifiable {

}
