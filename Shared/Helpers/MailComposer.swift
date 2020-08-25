//
//  MailComposer.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 19/08/2020.
//

import Foundation
import SwiftUI
import MessageUI

struct MailComposer: UIViewControllerRepresentable {
    @EnvironmentObject private var appState: AppState
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.setToRecipients(["bl3yd3r@hotmail.com"])
        mail.setMessageBody("The following log was emitted: \n" + appState.errorMessage, isHTML: false)
        mail.setSubject("Error log emitted by Tsuki manga reader app")
        
        return mail
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        DispatchQueue.main.async {
            appState.errorOccured = false
        }
        print("tried to dismiss")
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        //
    }
    
    typealias UIViewControllerType = MFMailComposeViewController
}
