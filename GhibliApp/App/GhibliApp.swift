//
//  GhibliApp.swift
//  GhibliApp
//
//  Created by Lucas Nascimento on 06/01/26.
//

import SwiftUI

@main
struct GhibliApp: App {
    private let container = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            RootView(router: container.router, container: container)
        }
    }
}
