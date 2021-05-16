//
//  AccountView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 22/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct LogInView: View {
    @EnvironmentObject var appState: AppState
    
    @AppStorage("userProfileId") var userProfileId: String = ""
    @AppStorage("MDListLink") var MDlListLink: String = ""
    
    @Binding var isPresented: Bool
    
    @State private var twoFactorCode: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    
    var testUsername: String = "ToaderTheBoi"
    var testPassword: String = "Pr0z6Po58jm3"
    
    @State private var loading: Bool = false
    @State private var errorOccured: Bool = false
    
    var body: some View {
        
        VStack(spacing: 100) {
            Text("Enter your credentials")
                .bold()
                .font(.title)
                .padding(.top, 50)
            
            VStack {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.username)
                    .keyboardType(.default)
                    .padding(.horizontal)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)
                    .padding(.horizontal)
                
                TextField("2FA code (optional)", text: $twoFactorCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                
                ZStack {
                    Text("Signing In...")
                        .foregroundColor(.gray)
                        .opacity(loading ? 1 : 0)
                        .animation(.default)
                    
                    Text("Something went wrong!")
                        .foregroundColor(.red)
                        .opacity(errorOccured ? 1 : 0)
                        .animation(.default)
                }
                
                Button(action: {isPresented = false}, label: {
                    Text("Continue without logging in")
                        .font(.system(size: 14))
                })
                Spacer()
                Text("Signing in gives you access to searching and saving mangas in the cloud. This action requires an account.")
                    .padding(.horizontal, 20)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12))
                
                Button(action: {
                    MDAuthentification.standard.logInToMD(username: username, password: password) { logInSuccessfull in
                        if logInSuccessfull {
                            DispatchQueue.main.async {
                                self.loading = false
                                self.isPresented = false
                            }
                        } else {
                            self.loading = false
                            self.errorOccured = true
                        }
                    }
                }, label: {
                    Text("Log In")
                        .bold()
                        .font(.system(size: 18))
                        .truncationMode(.tail)
                        .foregroundColor(Color.white)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .padding()
                })
            }.navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(Text("Final Step..."))
        }
    }
    
    func logIntoMD() {
        self.hideKeyboard()
        
        DispatchQueue.main.async {
            password = ""
            twoFactorCode = ""
            loading = true
            errorOccured = false
        }
        
        guard let url = URL(string: "https://mangadex.org/ajax/actions.ajax.php?function=login&nojs=1") else {
            print("From LogInVIew: Invalid URL")
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
            if ( checkLogInStatus() ) {
                //The credentials were correct, so the session cookies were set.
                //We are logged in now.
                
                //Grab the user page URL (for the account view) and the mdlist url (for the library view)
                do {
//                    let doc: Document = try SwiftSoup.parse(String(data: data ?? Data(), encoding: .utf8) ?? "")
//
//                    let linkList = try doc.getElementById("homepage_cog")?.siblingElements().first()?.select("div").first()?.children().array()
//
//                    var tempLink: String? = try linkList?[0].attr("href")
//                    let userProfile: String = tempLink == nil ? "" : (tempLink ?? "")
//
//                    tempLink = try linkList?[4].attr("href")
//                    let MDList: String = tempLink == nil ? "" : "https://mangadex.org" + (tempLink ?? "")
//
//                    DispatchQueue.main.async {
//                        self.MDlListLink = MDList
//                        self.userProfileId = userProfile.components(separatedBy: "/")[2]
//                        self.loading = false
//                        self.isPresented = false
//                    }
//
//                    //Copy the cookies in a shared container, so the widget can access them as well
//                    let widgetCookieStorage = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "group.TsukiApp")
//                    for cookie in URLSession.shared.configuration.httpCookieStorage?.cookies ?? [] {
//                        if ( cookie.name == "mangadex_session" || cookie.name == "mangadex_rememberme_token" ) {
//                            widgetCookieStorage.setCookie(cookie)
//                        }
//                    }
                    
                    return
                }// catch {
//                    print ("error")
//                    DispatchQueue.main.async {
//                        self.loading = false
//                        self.errorOccured = true
//                        appState.errorMessage += "Unknown error when parsing response from server.\n\n"
//                        withAnimation {
//                            appState.errorOccured = true
//                        }
//                    }
//                    return
//                }
            } else {
                //Couldn't log in for some reaseon
                DispatchQueue.main.async {
                    self.loading = false
                    self.errorOccured = true
                }
            }
        }.resume()
    }
    
    func addToRequestBody(body: NSMutableData, key: String, value: String, boundaryPrefix: String) {
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView(isPresented: Binding.constant(true))
            .previewDevice("iPhone 11 Pro")
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: .utf8)
        append(data!)
    }
}
