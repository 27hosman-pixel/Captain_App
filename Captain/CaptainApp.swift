//
//  CaptainApp.swift
//  Captain
//
//  Created by Hana Osman on 3/6/26.
//

import SwiftUI
import UserNotifications

@main
struct CaptainApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var previewStore = PreviewStore()
    @StateObject private var sessionStore = SessionStore()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(previewStore)
                .environmentObject(sessionStore)
        }
    }
}

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // User tapped the notification - could navigate to log screen here
        if response.notification.request.content.categoryIdentifier == "SESSION_REMINDER" {
            // Post notification to switch to log tab
            NotificationCenter.default.post(name: Notification.Name("SwitchToLogTab"), object: nil)
        }
        completionHandler()
    }
}
