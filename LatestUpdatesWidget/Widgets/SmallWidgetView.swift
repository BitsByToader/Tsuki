//
//  SmallWidgetView.swift
//  LatestUpdatesWidgetExtension
//
//  Created by Tudor Ifrim on 20/09/2020.
//

import SwiftUI

struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 5) {
                VStack {
                    NetworkImage(url: URL(string: entry.mangas.mangas[0].cover))
                        .clipShape(ContainerRelativeShape())
                    Text(entry.mangas.placeholder ? "Manga title" : "\(entry.mangas.mangas[0].title)")
                        .bold()
                        .foregroundColor(Color("WidgetForegroundColor"))
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }.padding(.horizontal, 10)
                .if(entry.mangas.placeholder || entry.mangas.mangas[0].isPlaceholder) { $0.redacted(reason: .placeholder) }
            }
            Spacer()
        }
    }
}

struct SmallWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SmallWidgetView(entry: SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil))
    }
}
