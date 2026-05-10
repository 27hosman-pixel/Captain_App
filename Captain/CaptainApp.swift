//
//  CaptainApp.swift
//  Captain
//
//  Created by Hana Osman on 3/6/26.
//

import SwiftUI

@main
struct CaptainApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var previewStore = PreviewStore()
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var authStore = AuthStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(previewStore)
                .environmentObject(sessionStore)
                .environmentObject(authStore) // make AuthStore available to the whole tree
        }
    }
}
