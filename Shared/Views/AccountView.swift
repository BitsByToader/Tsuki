//
//  AccountView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 28/08/2020.
//

import SwiftUI
import SwiftSoup
import SDWebImageSwiftUI

struct AccountView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var profileStats: [ProfileStat] = []
    @State private var profilePicURL: String = ""
    @State private var username: String = ""
    
    @State private var logInViewPresented: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(alignment: .center, spacing: 10) {
                        WebImage(url: URL(string: profilePicURL))
                            .resizable()
                            .placeholder {
                                Rectangle().foregroundColor(.gray)
                                    .opacity(0.2)
                            }
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFit()
                            .frame(height: 75)
                            .cornerRadius(12)
                        
                        Text(username)
                            .bold()
                            .font(.title3)
                            .lineLimit(1)
                    }
                }
                
                Section {
                    ForEach(profileStats, id: \.self) { stat in
                        HStack {
                            Text(stat.label)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(stat.value)
                        }
                    }
                }
                
                Section {
                    Button(action: {logInViewPresented = true}, label: {
                        Text("Change Account")
                    }).sheet(isPresented: $logInViewPresented) {
                        LogInView(isPresented: $logInViewPresented)
                    }
                    
                    Button(action: logOut, label: {
                        Text("Sign Out")
                            .foregroundColor(Color(.systemRed))
                    })
                }
            }.listStyle(InsetGroupedListStyle())
            .navigationTitle("Your Account")
            .navigationBarTitleDisplayMode(.large)
            .transition(.fade)
        }.onAppear(perform: loadAccountInformation)
    }
    
    func loadAccountInformation() {
        appState.isLoading = true
        
        guard let url = URL(string: "https://mangadex.org/user/915553/toadertheboi/") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let doc: Document = try SwiftSoup.parse(String(data: data, encoding: .utf8)!)
                    
                    let username: String = try doc.select("span.mx-1").text()
                    
                    let profileData = try doc.getElementsByClass("row edit").first()?.children().array()
                    
                    let profilePic: String = try profileData![0].select("div").first()!.select("img").attr("src")
                    
                    let profile = try profileData![1].select("div").first()?.children().array()
                    var stats: [ProfileStat] = []
                    
                    for index in 0...4 {
                        let label: String = try profile![index].child(0).text()
                        let value: String = try profile![index].child(1).text()
                        
                        stats.append(ProfileStat(label: label, value: value))
                    }
                    
                    DispatchQueue.main.async {
                        self.profilePicURL = profilePic
                        self.profileStats = stats
                        self.username = username
                    }
                    
                    return
                } catch Exception.Error(let type, let message) {
                    print ("Error of type \(type): \(message)")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Error when parsing response from server. \nType: \(type) \nMessage: \(message)\n\n"
                        withAnimation {
                            appState.errorOccured = true
                        }
                    }
                    return
                } catch {
                    print ("error")
                    DispatchQueue.main.async {
                        appState.errorMessage += "Unknown error when parsing response from server.\n\n"
                        withAnimation {
                            appState.errorOccured = true
                        }
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                withAnimation {
                    appState.errorOccured = true
                }
            }
            return
        }.resume()
    }
    
    func logOut() {
        let cookies: [HTTPCookie] = (URLSession.shared.configuration.httpCookieStorage?.cookies)!
        
        for cookie in cookies {
            if ( cookie.name == "mangadex_session" || cookie.name == "mangadex_rememberme_token" ) {
                URLSession.shared.configuration.httpCookieStorage?.deleteCookie(cookie)
            }
        }
        
        DispatchQueue.main.async {
            self.username = ""
            self.profilePicURL = ""
            self.profileStats = []
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}

struct ProfileStat: Hashable {
    let label: String
    let value: String
}
