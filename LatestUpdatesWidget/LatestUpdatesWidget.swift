//
//  LatestUpdatesWidget.swift
//  LatestUpdatesWidget
//
//  Created by Tudor Ifrim on 11/09/2020.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        
        UpdatedMangas.getLibraryUpdates { mangas, error in
            guard let mangas = mangas else {
                entries = [SimpleEntry(date: Calendar.current.date(byAdding: .hour, value: 0, to: currentDate)!, mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil)]
                
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
                
                return
            }
            let relevance = TimelineEntryRelevance(score: Float( mangas.relevance))
            entries  = [SimpleEntry(date: Calendar.current.date(byAdding: .hour, value: 0, to: currentDate)!, mangas: mangas, relevance: relevance)]
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let mangas: UpdatedMangas
    let relevance: TimelineEntryRelevance?
}

struct PlaceholderView : View {
    var entry: Provider.Entry = SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil)
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            Color("WidgetBackgroundColor")
            
            if family == .systemMedium {
                MediumWidgetView(entry: entry)
                    .redacted(reason: .placeholder)
            } else if family == .systemSmall {
                SmallWidgetView(entry: entry)
                    .redacted(reason: .placeholder)
            } else if family == .systemLarge {
                LargeWidgetView(entry: entry)
                    .redacted(reason: .placeholder)
            }
        }.widgetURL(URL(string: "tsuki:///latestupdates"))
    }
}

struct LatestUpdatesWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            Color("WidgetBackgroundColor")
            
            if family == .systemMedium {
                MediumWidgetView(entry: entry)
            } else if family == .systemSmall {
                SmallWidgetView(entry: entry)
            } else if family == .systemLarge {
                LargeWidgetView(entry: entry)
            }
        }.widgetURL(URL(string: "tsuki:///latestupdates"))
    }
}

@main
struct LatestUpdatesWidget: Widget {
    let kind: String = "LatestUpdatesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LatestUpdatesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Latest updates")
        .description("View all your library's updates at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LatestUpdatesWidget_Previews: PreviewProvider {
    static var previews: some View {
        LatestUpdatesWidgetEntryView(entry: SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct NetworkImage: View {
    let url: URL?
    
    var body: some View {
        Group {
            if let url = url, let imageData = try? Data(contentsOf: url),
               let uiImage = UIImage(data: imageData) {
                
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            else {
                Rectangle()
                    .fill(Color.gray)
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}
