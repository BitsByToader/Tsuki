//
//  AccountView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 28/08/2020.
//

import SwiftUI
import SDWebImageSwiftUI

struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("userProfileId") var userProfileId: String = ""
    @AppStorage("readingDataSaver") var readingDataSaver: Bool = false
    @AppStorage("downloadingDataSaver") var downloadingDataSaver: Bool = false
    
    @State var pickedLanguages: [String] = []
    
    private var logInButtonString: LocalizedStringKey {
        return loggedIn ? "Change account" : "Sign In"
    }
    
    var dateFormatter: DateFormatter {
        let obj: DateFormatter = DateFormatter()
        obj.dateStyle = .long
        
        return obj
    }
    
    @State private var loggedIn: Bool = false
    
//    @State private var profileStats: User = User(profilePicURL: "", username: "", joined: 0, lastSeen: 0, userId: 0, premium: false)
    
    @State private var logInViewPresented: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(alignment: .center, spacing: 10) {
                        WebImage(url: URL(string: ""))
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
                        
                        Text("username")
                            .bold()
                            .font(.title3)
                            .lineLimit(1)
                    }
                }
                if loggedIn {
                    Section(header: Text("User information")) {
                        ProfileStat(label: "User ID:", value: "1234")
                        
                        ProfileStat(label: "Joined:", value: "May, 20th, 1969.")
                        
                        ProfileStat(label: "Last online:", value: "May, 20th 1969")
                        
                        ProfileStat(label: "Premium Member:", value: "No")
                    }
                }
                
                Section(header: Text("Data Saver"), footer: Text("When enabling data saver, the chapter pages will be of a lesser quality, in an attempt to save bandwith. This may result in a worse reading experience.")) {
                    Toggle("Save data when reading", isOn: $readingDataSaver)
                    
                    Toggle("Save data when downloading", isOn: $downloadingDataSaver)
                }
                
                Section(header: Text("Languages"), footer: Text("If no languages are selected, then chapters from all languages will be loaded.")) {
                    NavigationLink(destination: LanguagePickerView(pickedLanguages: $pickedLanguages)) {
                        HStack {
                            Text("Picker")
                            
                            Spacer()
                            
                            Text("\(pickedLanguages.isEmpty ? "All languages" : "\(pickedLanguages.count) languages" )")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Account actions")) {
                    Button(action: {logInViewPresented = true}, label: {
                        Text(logInButtonString)
                    }).sheet(isPresented: $logInViewPresented) {
                        LogInView(isPresented: $logInViewPresented)
                    }
                    
                    if loggedIn {
                        Button(action: {
                            MDAuthentification.standard.logOut()
                            loggedIn = false
                        }, label: {
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
            self.pickedLanguages = UserDefaults.standard.stringArray(forKey: "pickedLanguages") ?? []
            
            let loadingDescription: LocalizedStringKey = "Loading account..."
            appState.loadingQueue.append(loadingDescription)
            
            MDAuthentification.standard.logInProcedure { isLoggedIn in
                if isLoggedIn {
                    print("Loading account information")
                    
                    //loadAccountInformation()
                    
                    DispatchQueue.main.async {
                        loggedIn = true
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                    }
                } else {
                    print("Showing log in view...")
                    
                    DispatchQueue.main.async {
                        loggedIn = false
                        appState.removeFromLoadingQueue(loadingState: loadingDescription)
                        logInViewPresented = true
                    }
                }
            }
        }
    }
    
    /*func loadAccountInformation() {
        let loadingDescription: LocalizedStringKey = "Loading account..."
        appState.loadingQueue.append(loadingDescription)
        
        guard let url = URL(string: "https://api.mangadex.org/v2/user/\(userProfileId)") else {
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
    }*/
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
