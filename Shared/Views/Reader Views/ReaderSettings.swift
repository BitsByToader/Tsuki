//
//  ReaderSettings.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 16.11.2020.
//

import SwiftUI
#warning("Localize strings")
#warning("Extend the UserDefaults class to accept storage of ReaderStyle and ReaderOrientation")

struct ReaderSettings: View {
    @AppStorage("readerStyle") var readerStyle: String = ReaderStyle.Scroll.rawValue
    @AppStorage("readerOrientation") var readerOrientation: String = ReaderOrientation.Horizontal.rawValue
    @AppStorage("fancyAnimations") var fancyAnimations: Bool = true
    @AppStorage("readingDataSaver") var readingDataSaver: Bool = false
    
    @Binding var settingsPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Style"), footer: Text("Choose your favorite style, either scroll between pages or swipe your way through a chapter.")) {
                    HStack {
                        Text("Reader style")
                            .padding(.trailing, 20)
                        
                        Spacer()
                        
                        Picker("Reader style", selection: $readerStyle) {
                            ForEach(ReaderStyle.allCases) {
                                Text($0.rawValue).tag($0)
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                if readerStyle == "Swipe" {
                    Section(header: Text("Swipe-based reader options"), footer: Text("These changes will take effect only after reloading the reader,switching to scrolling mode and back, or toggling the fullscreen mode.")) {
                        HStack {
                            Text("Reader orientation")
                                .padding(.trailing, 20)
                            
                            Spacer()
                            
                            Picker("Reader style", selection: $readerOrientation) {
                                ForEach(ReaderOrientation.allCases) {
                                    Text($0.rawValue).tag($0)
                                }
                            }.pickerStyle(SegmentedPickerStyle())
                        }
                        
                        if readerOrientation == "Horizontal" {
                            Toggle("Fancy animations", isOn: $fancyAnimations)
                        }
                    }
                }
                
                Section(header: Text("Data saver"), footer: Text("When enabling data saver, the chapter pages will be of a lesser quality, in an attempt to save bandwith. This may result in a worse reading experience.")) {
                    Toggle("Save data when reading", isOn: $readingDataSaver)
                }
            }.listStyle(GroupedListStyle())
            .navigationBarItems(trailing: Button(action: {settingsPresented.toggle()}, label: {Text("Done")}))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Reader Settings"))
            .onChange(of: readerOrientation, perform: { newValue in
                if ( newValue == "Vertical" ) {
                    fancyAnimations = false
                }
            })
        }
    }
    
    enum ReaderStyle: String, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        
        case Scroll
        case Swipe
    }
    
    enum ReaderOrientation: String, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        
        case Horizontal
        case Vertical
    }
}
