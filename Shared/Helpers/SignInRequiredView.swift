//
//  SignInRequiredView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 29/08/2020.
//

import SwiftUI

struct SignInRequiredView: View {
    var description: LocalizedStringKey
    @Binding var logInViewPresented: Bool
    
    var body: some View {
        VStack {
            Text(description)
                .multilineTextAlignment(.center)
            
            Button(action: {logInViewPresented = true}, label: {
                Text("Sign in...")
            }).sheet(isPresented: $logInViewPresented) {
                LogInView(isPresented: $logInViewPresented)
            }
        }
    }
}
