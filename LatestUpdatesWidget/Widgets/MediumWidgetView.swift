//
//  MediumWidgetView.swift
//  LatestUpdatesWidgetExtension
//
//  Created by Tudor Ifrim on 20/09/2020.
//

import SwiftUI

struct MediumWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 5) {
                ForEach((0..<3)) { index in
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

struct MediumWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        MediumWidgetView(entry: SimpleEntry(date: Date(), mangas: UpdatedMangas(numberOfPlaceholder: 6), relevance: nil))
    }
}
