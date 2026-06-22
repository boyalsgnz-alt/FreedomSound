//
//  utils.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/06/2026.
//

import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            print("Permission error: \(error)")
        }
    }
}

func scheduleExpiryReminder() {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()

    let installDate = UserDefaults.standard.object(forKey: "installDate") as? Date ?? Date()
    
    if UserDefaults.standard.object(forKey: "installDate") == nil {
        UserDefaults.standard.set(Date(), forKey: "installDate")
    }

    let expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: installDate)!
    let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: expiryDate)!

    let content = UNMutableNotificationContent()
    content.title = "App Expiring Soon"
    content.body = "Your app will expire tomorrow. Reinstall it to continue using it."
    content.sound = .default

    let trigger = UNCalendarNotificationTrigger(
        dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                      from: reminderDate),
        repeats: false
    )

    let request = UNNotificationRequest(
        identifier: "expiryReminder",
        content: content,
        trigger: trigger
    )

    center.add(request)
}
