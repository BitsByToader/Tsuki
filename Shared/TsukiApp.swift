//
//  TsukiApp.swift
//  Shared
//
//  Created by Tudor Ifrim on 21/07/2020.
//

import SwiftUI
import CoreData

#warning("Localize more strings!")

@main
struct TsukiApp: App {
    @StateObject var appState: AppState = AppState()
    @StateObject var tags: MangaTags = MangaTags()
    @StateObject var widgetURL: WidgetURL = WidgetURL()
    
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var persistentStore = PersistentStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(tags)
                .environmentObject(widgetURL)
                .environment(\.managedObjectContext, persistentStore.context)
            
        }.onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                print("\(#function) REPORTS - App change of scenePhase to ACTIVE")
            case .inactive:
                print("\(#function) REPORTS - App change of scenePhase to INACTIVE")
            case .background:
                print("\(#function) REPORTS - App change of scenePhase to BACKGROUND")
                savePersistentStore()
            @unknown default:
                fatalError("\(#function) REPORTS - fatal error in switch statement for .onChange modifier")
            }
        }
    }
    
    func savePersistentStore() {
        persistentStore.save()
    }
}

struct TsukiApp_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}

extension View {
    func checkLogInStatus() -> Bool {
        var sessionCookieFound: Bool = false
        var remindMeCookieFound: Bool = false
        
        for cookie in URLSession.shared.configuration.httpCookieStorage?.cookies ?? [] {
            if ( cookie.name == "mangadex_session" ) {
                sessionCookieFound = true
            } else if ( cookie.name == "mangadex_rememberme_token" ) {
                remindMeCookieFound = true
            }
        }
        
        return sessionCookieFound && remindMeCookieFound
    }
}
