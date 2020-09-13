//
//  WidgetURL.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 13/09/2020.
//

import Foundation

class WidgetURL: ObservableObject {
    @Published var openedWithURL: Bool = false
    @Published var url: URL?
}
