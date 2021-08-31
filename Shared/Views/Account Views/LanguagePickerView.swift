//
//  LanguagePickerView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 28.07.2021.
//

import SwiftUI

struct LanguagePickerView: View {
    @Binding var pickedLanguages: [String]
    @Binding var preferredLanguage: String
    
    var body: some View {
        List {
            ForEach(Array(languagesDict.keys.sorted()), id: \.self) { languageKey in
                Button(action: {
                    if ( !pickedLanguages.contains(languageKey) && preferredLanguage != languageKey ) {
                        self.pickedLanguages.append(languageKey)
                    } else if ( pickedLanguages.contains(languageKey) && preferredLanguage != languageKey ) {
                        self.preferredLanguage = languageKey
                    } else if ( pickedLanguages.contains(languageKey) && preferredLanguage == languageKey ) {
                        self.pickedLanguages.remove(at: pickedLanguages.firstIndex(of: languageKey) ?? 0)
                        self.preferredLanguage = ""
                    } else if ( preferredLanguage == languageKey ) {
                        self.preferredLanguage = ""
                    }
                    
                    UserDefaults(suiteName: "group.TsukiApp")?.set(self.preferredLanguage, forKey: "preferredLanguage")
                    UserDefaults(suiteName: "group.TsukiApp")?.set(self.pickedLanguages, forKey: "pickedLanguages")
                }, label: {
                    HStack(spacing: 10) {
                        Text(languagesDict[languageKey] ?? "Unknown language")
                        
                        Text(languagesEmojiDict[languageKey] ?? "")
                        
                        Spacer()
                        
                        HStack {
                            Text("Preferred")
                                .font(Font.headline.smallCaps())
                                .lineLimit(1)
                                
                            Image(systemName: "checkmark")
                        }.foregroundColor(Color.accentColor)
                        .opacity(preferredLanguage == languageKey ? 1 : 0)
                        .animation(.default)
                        
                        HStack {
                            Text("Selected")
                                .font(Font.headline.smallCaps())
                                .lineLimit(1)
                            
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
