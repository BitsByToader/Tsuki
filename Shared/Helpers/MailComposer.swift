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
    @Binding var viewDismissed: Bool
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.setToRecipients(["tudorifrim@icloud.com"])
        mail.setMessageBody("The following log was emitted: \n" + appState.errorMessage, isHTML: false)
        mail.setSubject("Error log emitted by Tsuki manga reader app")
        
        return mail
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        appState.errorOccured = false
        print("tried to dismiss")
        viewDismissed = true
        controller.dismiss(animated: false)
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        //
    }
    
    typealias UIViewControllerType = MFMailComposeViewController
}
