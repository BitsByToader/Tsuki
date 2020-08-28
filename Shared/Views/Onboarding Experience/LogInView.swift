//
//  AccountView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 22/07/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct LogInView: View {
    //    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    
    @State private var twoFactorCode: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    
    //    init() {
    //        UINavigationBar.appearance().barTintColor = .clear
    //        UINavigationBar.appearance().backgroundColor = .clear
    //        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
    //        UINavigationBar.appearance().shadowImage = UIImage()
    //    }
    
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
            DispatchQueue.main.async {
                username = ""
                password = ""
                twoFactorCode = ""
            }
        }.resume()
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
