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
        VStack() {
            Image(systemName: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                .font(.system(size: 35, weight: .semibold))
                .frame(minWidth: 44, minHeight: 44)
            Spacer()
            Text("\(timeRemaining)")
                .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                    now = Date()
                }
                .font(.system(size: 30, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("before expiration")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    var timeRemaining: String {
        let diff = Int(expiryDate.timeIntervalSince(now))
        if diff <= 0 {
            return "Expired"
        }

        let days = diff / 86400
        let hours = (diff % 86400) / 3600

        return "\(days)d \(hours)h"
    }
}
