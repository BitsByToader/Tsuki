//
//  ErrorView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 18/08/2020.
//

import SwiftUI
import MessageUI

struct ErrorView: View {
    @EnvironmentObject var appState: AppState
    @State private var isShowingMailComposer: Bool = false
    
    var body: some View {
        VStack {
            Spacer(minLength: 25)
            
            Text("Here's you error")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            GeometryReader { values in
                ZStack {
                    Rectangle()
                        .fill(Color(.tertiarySystemFill))
                        .cornerRadius(8)
                    
                    ScrollView {
                        Text(appState.errorMessage)
                            .padding(10)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(15)
                .frame(height: (80 * values.size.height ) / 100 )
            }
            
            VStack(spacing: 15) {
                Text("Send to developer")
                    .bold()
                    .truncationMode(.tail)
                    .padding(10)
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    .background(Color.accentColor)
                    .foregroundColor(Color.white)
                    .frame(minWidth: 0, minHeight: 0)
                    .cornerRadius(10)
                    .onTapGesture {
                        isShowingMailComposer = true
                    }
                    .sheet(isPresented: $isShowingMailComposer) {
                        if MFMailComposeViewController.canSendMail() {
                            MailComposer()
                        } else {
                            Text("Can't send emails from this device :(")
                        }
                    }
                
                Text("Copy to clipboard")
                    .foregroundColor(Color.accentColor)
                    .onTapGesture {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = appState.errorMessage
                        
                        appState.errorOccured = false
                    }
            }
            
            Spacer(minLength: 25)
        }.onAppear {
            print(appState.errorMessage)
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView()
    }
}
