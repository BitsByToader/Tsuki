//
//  AccountView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 22/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct AccountView: View {
    @EnvironmentObject var appState: AppStates
//    let username: String = "ToaderTheBoi"
//    let password: String = "Pr0z6Po58jm3"
    
    @State private var MDresponse: String = ""
    
    @State private var twoFactorCode: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("2FA", text: $twoFactorCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: logIntoMD, label: {
                    Text("Log In")
                })
                Button(action: logOut, label: {
                    Text("Log Out")
                })
                Button(action: checkStatus, label: {
                    Text("Check Cookies")
                })
                
                Button(action: {
                    withAnimation {
                        appState.errorOccured.toggle()
                    }
                    
                }, label: {
                    Text("Toggle error")
                })
                Text(MDresponse)
                
            }.navigationTitle(Text("Your account"))
        }
    }
    
    func logIntoMD() {
        guard let url = URL(string: "https://mangadex.org/ajax/actions.ajax.php?function=login&nojs=1") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = true
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let boundaryPrefix = "--\(boundary)\r\n"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        let payload: NSMutableData = NSMutableData()
        addToRequestBody(body: payload, key: "login_username", value: username, boundaryPrefix: boundaryPrefix)
        addToRequestBody(body: payload, key: "login_password", value: password, boundaryPrefix: boundaryPrefix)
        addToRequestBody(body: payload, key: "remember_me", value: "1", boundaryPrefix: boundaryPrefix)
        addToRequestBody(body: payload, key: "two_factor", value: twoFactorCode, boundaryPrefix: boundaryPrefix)
        
        URLSession.shared.uploadTask(with: request, from: payload as Data? ) { data, response, error in
            // step 4
            MDresponse = String(data: data!, encoding: .utf8)!
        }.resume()
    }
    
    func logOut() {
        let cookies: [HTTPCookie] = (URLSession.shared.configuration.httpCookieStorage?.cookies)!
        
        for cookie in cookies {
            if ( cookie.name == "mangadex_session" || cookie.name == "mangadex_rememberme_token" ) {
                URLSession.shared.configuration.httpCookieStorage?.deleteCookie(cookie)
            }
        }
    }
    
    func checkStatus() {
        print(URLSession.shared.configuration.httpCookieStorage?.cookies as Any)
    }
    
    func addToRequestBody(body: NSMutableData, key: String, value: String, boundaryPrefix: String) {
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: .utf8)
        append(data!)
    }
}
