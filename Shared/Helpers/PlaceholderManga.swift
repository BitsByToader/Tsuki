//
//  PlaceholderManga.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 11/10/2020.
//

import SwiftUI

struct PlaceholderManga: View {
    var body: some View {
        VStack {
            Spacer()
            
            Color.init(.secondarySystemBackground)
                .padding(.all, 5)
                .frame(height: 180)
            
            Text("Placeholder title to fill 2 lines")
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 10)
            
            Spacer()
        }.frame(width: 125, height: 250)
        .redacted(reason: .placeholder)
    }
}

struct PlaceholderManga_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderManga()
    }
}
