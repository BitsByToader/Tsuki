//
//  AppState.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 24/08/2020.
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var loadingQueue: [String] = []
    @Published var errorOccured: Bool = false
    @Published var errorMessage: String = ""
    
    func removeFromLoadingQueue(loadingState: String) {
        for index in 0..<loadingQueue.count {
            if loadingQueue[index] == loadingState {
                loadingQueue.remove(at: index)
                break
            }
        }
    }
}
