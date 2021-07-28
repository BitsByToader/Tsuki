//
//  LanguagePickerView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 28.07.2021.
//

import SwiftUI

struct LanguagePickerView: View {
    @Binding var pickedLanguages: [String]
    
    var body: some View {
        List {
            ForEach(Array(languagesDict.keys.sorted()), id: \.self) { languageKey in
                Button(action: {
                    if ( pickedLanguages.contains(languageKey) ) {
                        self.pickedLanguages.remove(at: pickedLanguages.firstIndex(of: languageKey) ?? 0)
                    } else {
                        self.pickedLanguages.append(languageKey)
                    }
                    
                    UserDefaults.standard.set(self.pickedLanguages, forKey: "pickedLanguages")
                }, label: {
                    HStack(spacing: 10) {
                        Text(languagesDict[languageKey] ?? "Unknown language")
                        
                        Text(languagesEmojiDict[languageKey] ?? "")
                        
                        Spacer()
                        
                        HStack {
                            Text("Selected")
                                .font(Font.headline.smallCaps())
                            Image(systemName: "checkmark")
                        }.foregroundColor(Color.accentColor)
                        .opacity(pickedLanguages.contains(languageKey) ? 1 : 0)
                        .animation(.default)
                    }
                })
            }
        }.listStyle(InsetGroupedListStyle())
        .navigationTitle("Languages")
        .navigationBarTitleDisplayMode(.large)
    }
}
