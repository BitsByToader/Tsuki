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
    @AppStorage("userProfileId") var userProfileId: String = ""
    @AppStorage("readingDataSaver") var readingDataSaver: Bool = false
    @AppStorage("downloadingDataSaver") var downloadingDataSaver: Bool = false
    
    private var logInButtonString: LocalizedStringKey {
        return checkLogInStatus() ? "Change account" : "Sign In"
    }
    
    private var loggedIn: Bool {
        return checkLogInStatus()
    }
    
    var dateFormatter: DateFormatter {
        let obj: DateFormatter = DateFormatter()
        obj.dateStyle = .long
        
        return obj
    }
    
    @State private var profileStats: User = User(profilePicURL: "", username: "", joined: 0, lastSeen: 0, userId: 0, premium: false)
    
    @State private var logInViewPresented: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(alignment: .center, spacing: 10) {
                        WebImage(url: URL(string: profileStats.profilePicURL ?? "https://mangadex.org/images/avatars/default1.jpg"))
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
                        
                        Text(profileStats.username)
                            .bold()
                            .font(.title3)
                            .lineLimit(1)
                    }
                }
                if loggedIn {
                    Section {
                        ProfileStat(label: "User ID:", value: "\(profileStats.userId)")
                        
                        ProfileStat(label: "Joined:", value: "\(dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(profileStats.joined))))")
                        
                        ProfileStat(label: "Last online:", value: "\(dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(profileStats.lastSeen))))")
                        
                        ProfileStat(label: "Premium Member:", value: profileStats.premium ? "Yes" : "No")
                    }
                }
                
                Section(header: Text("Data Saver"), footer: Text("When enabling data saver, the chapter pages will be of a lesser quality, in an attempt to save bandwith. This may result in a worse reading experience.")) {
                    Toggle("Save data when reading", isOn: $readingDataSaver)
                    
                    Toggle("Save data when downloading", isOn: $downloadingDataSaver)
                }
                
                Section {
                    Button(action: {logInViewPresented = true}, label: {
                        Text(logInButtonString)
                    }).sheet(isPresented: $logInViewPresented) {
                        LogInView(isPresented: $logInViewPresented)
                    }
                    
                    if loggedIn {
                        Button(action: logOut, label: {
                            Text("Sign Out")
                                .foregroundColor(Color(.systemRed))
                        })
                    }
                }
            }.listStyle(InsetGroupedListStyle())
            .navigationTitle("Your Account")
            .navigationBarTitleDisplayMode(.large)
            .transition(.fade)
        }.navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if (loggedIn) {
                loadAccountInformation()
            }
        }
    }
    
    func loadAccountInformation() {
        let loadingDescription: LocalizedStringKey = "Loading account..."
        appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "https://www.mangadex.org/api/v2/user/\(userProfileId)") else {
            print("From AccountView: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        print("From AccountView: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(DecodedUser.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.profileStats = decodedResponse.data
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                    
                    return
                } catch {
                    DispatchQueue.main.async {
                        appState.errorMessage += "An error occured during the decoding of the JSON response from the server.\nMessage: \(error)\n\n"
                        withAnimation {
                            appState.errorOccured = true
                            appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                appState.errorMessage += "Network fetch failed. \nMessage: \(error?.localizedDescription ?? "Unknown error")\n\n"
                withAnimation {
                    appState.errorOccured = true
                    appState.removeFromLoadingQueue(loadingState: loadingDescription)
                }
            }
            return
        }.resume()
    }
    
    func logOut() {
        logOutUser()
        
        DispatchQueue.main.async {
            profileStats = User(profilePicURL: "", username: "", joined: 0, lastSeen: 0, userId: 0, premium: false)
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}

struct ProfileStat: View {
    let label: LocalizedStringKey
    let value: LocalizedStringKey
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
        }
    }
}
