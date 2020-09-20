//
//  LargeWidgetView.swift
//  LatestUpdatesWidgetExtension
//
//  Created by Tudor Ifrim on 20/09/2020.
//

import SwiftUI

struct LargeWidgetView: View {
    var entry: Provider.Entry
    
    let columns = [
        GridItem(.adaptive(minimum: 80)),
        GridItem(.adaptive(minimum: 80)),
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach((0..<6)) { index in
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
        }
    }
}

struct LargeWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        LargeWidgetView(entry: SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil))
    }
}
