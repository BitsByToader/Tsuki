//
//  LibraryLink.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/08/2020.
//

import SwiftUI

struct LibraryLink: View {
    var linkTitle: LocalizedStringKey
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color(.secondarySystemBackground))
                .cornerRadius(12)

            HStack {
                Text(linkTitle)
                    .bold()
                    .buttonStyle(PlainButtonStyle())
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.systemGray))
            }.padding(.horizontal, 10)
            .padding(.vertical, 0)
        }.padding(.horizontal, 15)
        .frame(height: 50)
    }
}

struct LibraryLink_Previews: PreviewProvider {
    static var previews: some View {
        LibraryLink(linkTitle: "Press me")
    }
}
