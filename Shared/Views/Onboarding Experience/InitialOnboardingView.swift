//
//  InitialOnboardingView.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 28/08/2020.
//

import SwiftUI

struct InitialOnboardingView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 50) {
                    Text("Welcome to Tsuki")
                        .bold()
                        .font(.largeTitle)
                    
                    VStack(spacing: 15) {
                        OnboardingFeature(imageName: "newspaper.fill", imageColor: Color(.systemRed), featureName: "Today", featureDescription: "Discover today's hot manga, or the newest chapters. Your pick.")
                        
                        OnboardingFeature(imageName: "magnifyingglass", imageColor: Color(.systemGreen), featureName: "Explore", featureDescription: "Search for new manga, or maybe go through your favorite genres.")

                        OnboardingFeature(imageName: "books.vertical.fill", imageColor: Color(.systemBlue), featureName: "Library", featureDescription: "View all of your saved manga, in an instant, on all your devices.")
                        
                        OnboardingFeature(imageName: "person.crop.circle", imageColor: Color(.systemGray), featureName: "Account", featureDescription: "Manage your account and view all relevant stats.")
                    }.padding(.horizontal, 25)
                }
                
                Spacer()
                Spacer()
                
                NavigationLink(
                    destination: LogInView(isPresented: $isPresented),
                    label: {
                        Text("Continue")
                            .bold()
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                )
                Spacer(minLength: 60)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
            }
        }
    }
}

struct InitialOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        InitialOnboardingView(isPresented: Binding.constant(true))
    }
}

struct OnboardingFeature: View {
    let imageName: String
    let imageColor: Color
    let featureName: LocalizedStringKey
    let featureDescription: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: imageName)
                .padding(5)
                .font(.system(size: 40))
                .foregroundColor(imageColor)
                .frame(width: 55)
                
            
            VStack(alignment: .leading, spacing: 5) {
                Text(featureName)
                    .font(.subheadline)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                
                Text(featureDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
