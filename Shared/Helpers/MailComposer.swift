//
//  MailComposer.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 19/08/2020.
//

import Foundation
import SwiftUI

#if !os(macOS)
import MessageUI

struct MailComposer: UIViewControllerRepresentable {
    @EnvironmentObject private var appState: AppState
    @Binding var viewDismissed: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.setToRecipients(["bl3yd3r@hotmail.com"])
        mail.setMessageBody("The following log was emitted: \n" + appState.errorMessage, isHTML: false)
        mail.setSubject("Error log emitted by Tsuki manga reader app")
        
        mail.mailComposeDelegate = context.coordinator
        
        return mail
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        //
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposer
        
        init(_ mailViewController: MailComposer) {
            self.parent = mailViewController
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            //Dismiss the SheetView from SwiftUI
            parent.viewDismissed = false
        }
    }
}
#endif
