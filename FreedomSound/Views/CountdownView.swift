//
//  CountdownView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/06/2026.
//

import SwiftUI
import Combine

struct CountdownView: View {
    @State private var now = Date()

    let expiryDate: Date

    init() {
        expiryDate = getProvisioningProfileExpiration() ?? Date()
    }

    var body: some View {
        Text(timeRemaining)
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                now = Date()
            }
            .font(.headline)
    }

    var timeRemaining: String {
        let diff = Int(expiryDate.timeIntervalSince(now))
        if diff <= 0 {
            return "Expired"
        }

        let days = diff / 86400
        let hours = (diff % 86400) / 3600
        let minutes = (diff % 3600) / 60

        return "\(days)d \(hours)h \(minutes)m left"
    }
}
