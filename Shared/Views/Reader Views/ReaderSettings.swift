//
//  ReaderSettings.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 16.11.2020.
//

import SwiftUI
#warning("Localize strings")
struct ReaderSettings: View {
    @AppStorage("readerStyle") var readerStyle: String = ReaderStyle.Scroll.rawValue
    @AppStorage("readingDataSaver") var readingDataSaver: Bool = false
    
    @Binding var settingsPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Reader style")
                            .bold()
                            .padding(.trailing, 20)
                        
                        Spacer()
                        
                        Picker("Reader style", selection: $readerStyle) {
                            ForEach(ReaderStyle.allCases) {
                                Text($0.rawValue).tag($0)
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section {
                    Toggle("Save data when reading", isOn: $readingDataSaver)
                }
            }.listStyle(GroupedListStyle())
            .navigationBarItems(trailing: Button(action: {settingsPresented.toggle()}, label: {Text("Done")}))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Reader Settings"))
        }
    }
    
    enum ReaderStyle: String, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        
        case Scroll
        case Swipe
    }
}
