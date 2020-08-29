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
    
    func logOutUser() {
        let cookies: [HTTPCookie] = (URLSession.shared.configuration.httpCookieStorage?.cookies)!
        
        for cookie in cookies {
            if ( cookie.name == "mangadex_session" || cookie.name == "mangadex_rememberme_token" ) {
                URLSession.shared.configuration.httpCookieStorage?.deleteCookie(cookie)
            }
        }
        
        UserDefaults.standard.setValue("", forKey: "userProfileLink")
        UserDefaults.standard.setValue("", forKey: "MDListLink")
    }
}
