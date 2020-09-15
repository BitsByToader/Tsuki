//
//  LatestUpdatesWidget.swift
//  LatestUpdatesWidget
//
//  Created by Tudor Ifrim on 11/09/2020.
//

import WidgetKit
import SwiftUI
//import SwiftSoup

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
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

struct LatestUpdatesWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family
    private var numberOfItems: Int {
        switch family {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 3
        case .systemLarge:
            return 6
        @unknown default:
            return 1
        }
    }
    
    var body: some View {
        ZStack {
            Color("WidgetBackgroundColor")
            
            VStack {
                Spacer()
                HStack(spacing: 5) {
                    ForEach((0..<numberOfItems)) { index in
                        VStack {
                            NetworkImage(url: URL(string: entry.mangas.mangas[index].cover))
                                .clipShape(ContainerRelativeShape())
                            Text(entry.mangas.placeholder ? "Manga title" : "\(entry.mangas.mangas[index].title)")
                                .bold()
                                .foregroundColor(Color("WidgetForegroundColor"))
                                .font(.system(size: 12))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }.padding(.horizontal, 10)
                        .if(entry.mangas.placeholder) { $0.redacted(reason: .placeholder) }
                    }
                }
                Spacer()
            }.widgetURL(URL(string: "tsuki:///latestupdates"))
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
        .supportedFamilies([.systemMedium, .systemSmall])
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
