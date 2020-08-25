//
//  AppState.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 24/08/2020.
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorOccured: Bool = false
    @Published var errorMessage: String = ""
}
