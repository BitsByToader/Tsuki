//
//  SwipeReaderImage.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30.11.2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct SwipeReaderImage: View {
    var contentIsRemote: Bool
    var imageURL: String
    
    var body: some View {
        ScrollView {
            if contentIsRemote {
                WebImage(url: URL(string: imageURL)!)
                    .resizable()
                    .placeholder {
                        Rectangle().foregroundColor(.gray)
                            .opacity(0.2)
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
            } else {
                Image(uiImage: UIImage(contentsOfFile: imageURL)!)
                    .resizable()
                    .transition(.fade(duration:0.5))
                    .scaledToFit()
            }
        }
    }
}
