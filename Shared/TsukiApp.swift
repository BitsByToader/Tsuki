//
//  TsukiApp.swift
//  Shared
//
//  Created by Tudor Ifrim on 21/07/2020.
//

import SwiftUI

class AppStates: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorOccured: Bool = false
    @Published var errorMessage: String = ""
}

@main
struct TsukiApp: App {
    @StateObject var appState: AppStates = AppStates()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

struct TsukiApp_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}
