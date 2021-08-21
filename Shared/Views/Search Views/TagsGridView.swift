//
//  TagsGridView.swift
//  TagsGridView
//
//  Created by Tudor Ifrim on 21.08.2021.
//

import SwiftUI

struct TagsGridView: View {
    @Binding var tags: [Tag]
    var tagStateToDisplay: Tag.ToggleState
    var tagColorToDisplay: UIColor
    var headline: LocalizedStringKey
    
    var reloadList: () -> Void
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                Text(headline)
                    .font(.title2)
                    .bold()
                
                Text("Tap to remove")
                    .font(.footnote)
                    .italic()
                    .foregroundColor(.gray)
                    .frame(alignment: .center)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                ForEach( Array(tags.enumerated()), id: \.element.id ) { index, tag in
                    if tag.state == tagStateToDisplay {
                        Text(tag.name)
                            .bold()
                            .lineLimit(1)
//                                .fixedSize()
                            .foregroundColor(.white)
                            .padding(5)
                            .padding(.horizontal, 5)
                            .frame(height: 30)
                            .background(Color(tagColorToDisplay))
                            .cornerRadius(15)
                            .onTapGesture {
                                tags.remove(at: index)
                                reloadList()
                            }
                    }
                }
            }.animation(.default)
        }
    }
}
