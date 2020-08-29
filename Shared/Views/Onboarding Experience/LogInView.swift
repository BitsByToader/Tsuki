//
//  AccountView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 22/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftSoup

struct LogInView: View {
    @EnvironmentObject var appState: AppState
    
    @AppStorage("userProfileLink") var userProfileLink: String = ""
    @AppStorage("MDListLink") var MDlListLink: String = ""
    
    @Binding var isPresented: Bool
    
    @State private var twoFactorCode: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    
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
                
                Button(action: logIntoMD, label: {
                    Text("Log In")
                        .bold()
                        .font(.system(size: 18))
                        .truncationMode(.tail)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .frame(width: 300)
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(11)
                })
                
                Button(action: {isPresented = false}, label: {
                    Text("Continue without logging in")
                        .font(.system(size: 14))
                        .padding(.top, 10)
                })
                Spacer()
                Text("Signing in gives you access to searching and saving mangas in the cloud. This action requires a MangaDex account.")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12))
            }.navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(Text("Final Step..."))
        }
    }
    
    func logIntoMD() {
        DispatchQueue.main.async {
            password = ""
            twoFactorCode = ""
            loading = true
            errorOccured = false
        }
        
        logOutUser()
        
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
                    let doc: Document = try SwiftSoup.parse(String(data: data ?? Data(), encoding: .utf8) ?? "")
                    
                    let linkList = try doc.getElementById("homepage_cog")?.siblingElements().first()?.select("div").first()?.children().array()
                    
                    var tempLink: String? = try linkList?[0].attr("href")
                    let userProfile: String = tempLink == nil ? "" : "https://mangadex.org" + (tempLink ?? "")
                    
                    tempLink = try linkList?[4].attr("href")
                    let MDList: String = tempLink == nil ? "" : "https://mangadex.org" + (tempLink ?? "")
                    
                    DispatchQueue.main.async {
                        self.MDlListLink = MDList
                        self.userProfileLink = userProfile
                        self.loading = false
                        self.isPresented = false
                    }
                    
                    return
                }
                catch Exception.Error(let type, let message) {
                    print ("Error of type \(type): \(message)")
                    DispatchQueue.main.async {
                        self.loading = false
                        self.errorOccured = true
                        appState.errorMessage += "Error when parsing response from server. \nType: \(type) \nMessage: \(message)\n\n"
                        withAnimation {
                            appState.errorOccured = true
                        }
                    }
                    return
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        self.loading = false
                        self.errorOccured = true
                        appState.errorMessage += "Unknown error when parsing response from server.\n\n"
                        withAnimation {
                            appState.errorOccured = true
                        }
                    }
                    return
                }
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
