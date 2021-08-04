//
//  User.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 06.11.2020.
//
import SwiftUI
import SwiftKeychainWrapper

extension KeychainWrapper.Key {
    static let sessionToken: KeychainWrapper.Key = "sessionToken"
    static let refreshToken: KeychainWrapper.Key = "refreshToken"
}

final class MDAuthentification {
    static let standard = MDAuthentification()
    let tsukiKeychain = KeychainWrapper.init(serviceName: "com.toader.Tsuki")
    
    private init() {}
    
    //MARK: - MD Response struct
    struct LogInResponse: Codable {
        let result: String
        let token: ResponseToken?
        
        struct ResponseToken: Codable {
            let session: String
            let refresh: String
        }
    }
    
    //MARK: - Main login procedure used by the views for using logged user data.
    func logInProcedure(completion: @escaping (Bool) -> Void) {
        print("Begin login procedure...")
        
        DispatchQueue.global(qos: .utility).async {
            self.checkLogin { loggedIn in
                if !loggedIn {
                    //User is not logged in. Try and refresh the session token with the refresh token...
                    print("Not logged in, continuing...")
                    
                    self.getNewSessionToken { tokenRefreshed in
                        if !tokenRefreshed {
                            print("Refresh token expired.")
                            //The refresh token expired. Prompt the user to login again.
                            completion(false)
                        } else {
                            //The token was refreshed, that means we're logged in.
                            print("We're logged in with a new token.")
                            completion(true)
                        }
                    }
                } else {
                    //We're logged in. :)
                    print("Already logged in...")
                    completion(true)
                }
            }
        }
    }
    
    //MARK: - Log In method
    func logInToMD(username: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "")auth/login") else {
            print("From LogInVIew: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = true
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = Data("{\"username\":\"\(username)\",\"password\":\"\(password)\"}".utf8)
        
        URLSession.shared.uploadTask(with: request, from: payload) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(LogInResponse.self, from: data)
                    
                    if ( decodedResponse.result == "ok" ) {
                        print("Logged in.")
                        
                        self.tsukiKeychain[.sessionToken] = decodedResponse.token!.session
                        self.tsukiKeychain[.refreshToken] = decodedResponse.token!.refresh
                        
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    print(error)
                    completion(false)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
    
    //MARK: - Refresh the session token method
    func getNewSessionToken(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "")auth/refresh") else {
            print("From LogInVIew: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = true
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = Data("{\"token\":\"\(getRefreshToken())\"}".utf8)
        
        URLSession.shared.uploadTask(with: request, from: payload) { data, response, error in
            if let data = data {
                //                print( String(data: data, encoding: .utf8))
                do {
                    let decodedResponse = try JSONDecoder().decode(LogInResponse.self, from: data)
                    
                    if ( decodedResponse.result == "ok" ) {
                        
                        self.tsukiKeychain[.sessionToken] = decodedResponse.token!.session
                        self.tsukiKeychain[.refreshToken] = decodedResponse.token!.refresh
                        
                        completion(true)
                    } else if ( decodedResponse.result == "error" ) {
                        completion(false)
                    }
                } catch {
                    print(error)
                    
                    completion(false)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
    
    //MARK: - Check if the user is logged in
    func checkLogin(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "")auth/check") else {
            print("From LogInVIew: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getSessionToken())", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {data,response,error in
            if let data = data {
                do {
                    struct CheckLoginResponse: Codable {
                        let result: String
                        let isAuthenticated: Bool
                    }
                    
                    let decodedData = try JSONDecoder().decode(CheckLoginResponse.self, from: data)
                    
                    completion(decodedData.isAuthenticated)
                } catch {
                    print(error)
                    
                    completion(false)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
    
    //MARK: - Log out method
    func logOut() {
        guard let url = URL(string: "\(UserDefaults(suiteName: "group.TsukiApp")?.value(forKey: "apiURL") ?? "")auth/logout") else {
            print("From MDAuth: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getSessionToken())", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = data {
                self.tsukiKeychain[.refreshToken] = ""
                self.tsukiKeychain[.sessionToken] = ""
            }
        }.resume()
    }
    
    //MARK: - Keychain helpers
    func getSessionToken() -> String {
        return tsukiKeychain[.sessionToken] ?? ""
    }
    
    func getRefreshToken() -> String {
        return tsukiKeychain[.refreshToken] ?? ""
    }
}
