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

func requestNotificationPermission(completion: @escaping () -> Void = {}) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            print("Permission error: \(error)")
        }
        completion()
    }
}

func scheduleExpiryReminder() {
    let center = UNUserNotificationCenter.current()

        let expiryDate: Date
        if let saved = UserDefaults.standard.object(forKey: "appExpiryDate") as? Date {
            expiryDate = saved
        } else {
            expiryDate = getProvisioningProfileExpiration()
                ?? Calendar.current.date(byAdding: .day, value: 7, to: Date())!
            UserDefaults.standard.set(expiryDate, forKey: "appExpiryDate")
        }

        center.getPendingNotificationRequests { requests in
            guard !requests.contains(where: { $0.identifier == "expiryReminder" }) else { return }

            guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: expiryDate),
                  reminderDate > Date() else { return } // évite de programmer une date passée

            let content = UNMutableNotificationContent()
            content.title = "App Expiring Soon"
            content.body = "Your app will expire tomorrow. Reinstall it to continue using it."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: reminderDate),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "expiryReminder", content: content, trigger: trigger
            )
            center.add(request)
        }
}

func getProvisioningProfileExpiration() -> Date? {
    guard let profilePath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
          let profileData = try? Data(contentsOf: URL(fileURLWithPath: profilePath)) else {
        return nil
    }

    let xmlStart = Data("<?xml".utf8)
    let xmlEnd = Data("</plist>".utf8)

    guard let startRange = profileData.range(of: xmlStart),
          let endRange = profileData.range(of: xmlEnd) else {
        return nil
    }

    let plistData = profileData[startRange.lowerBound ..< endRange.upperBound]

    guard let plist = try? PropertyListSerialization.propertyList(
              from: plistData,
              options: [],
              format: nil
          ) as? [String: Any],
          let expirationDate = plist["ExpirationDate"] as? Date else {
        return nil
    }

    return expirationDate
}
