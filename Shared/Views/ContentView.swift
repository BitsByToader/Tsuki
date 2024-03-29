//
//  ContentView.swift
//  Shared
//
//  Created by Tudor Ifrim on 21/07/2020.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var widgetURL: WidgetURL
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    
    @State private var errorSheetPresented: Bool = false
    @State private var tabViewSelection: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                TabView(selection: $tabViewSelection) {
                    TodayView()
                        .tabItem {
                            Image(systemName: "newspaper.fill")
                            Text("Today")
                        }
                        .tag(0)
                    
                    SearchView()
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                        .tag(1)
                    
                    LibraryView()
                        .tabItem {
                            Image(systemName: "books.vertical.fill")
                            Text("Library")
                        }
                        .environmentObject(widgetURL)
                        .tag(2)
                    
                    AccountView()
                        .tabItem {
                            Image(systemName: "person.crop.circle")
                            Text("Account")
                        }
                        .tag(3)
                }.sheet(isPresented: $firstLaunch, content: {
                    InitialOnboardingView(isPresented: $firstLaunch)
                })
                .onOpenURL { url in
                    if ( url == URL(string: "tsuki:///latestupdates") ) {
                        widgetURL.openedWithURL = true
                        widgetURL.url = url
                        
                        self.tabViewSelection = 2
                    }
                }

                ZStack {
                    BlurView(style: .systemThickMaterial)
                        .cornerRadius(10)
                    
                    ProgressView(appState.loadingQueue.last ?? "")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }.frame(width: 150, height: 150)
                .opacity(!appState.loadingQueue.isEmpty ? 1 : 0)
                .animation(.default)
            }
            
            if appState.errorOccured {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemRed))
                        .cornerRadius(10)
                        .frame(height: 60)
                    
                    Text("Oh no :( \nA wild *ERROR* appeared! Tap for more info")
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 10)
                }.padding(10)
                .padding(.bottom, 0)
                .onTapGesture {
                    self.errorSheetPresented = true
                }
                .sheet(isPresented: $errorSheetPresented, onDismiss: {
                    withAnimation {
                        appState.errorOccured = false
                        
                    }
                }) {
                    ErrorView()
                        .environmentObject(self.appState)
                }.onAppear {
                    let hapticFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    hapticFeedback.impactOccurred()
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
}

struct BlurView : UIViewRepresentable {
    
    var style : UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
