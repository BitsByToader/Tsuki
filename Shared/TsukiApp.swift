//
//  TsukiApp.swift
//  Shared
//
//  Created by Tudor Ifrim on 21/07/2020.
//

import SwiftUI

@main
struct TsukiApp: App {
    @StateObject var appState: AppState = AppState()
    @StateObject var tags: MangaTags = MangaTags()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(tags)
        }
    }
}

struct TsukiApp_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}
