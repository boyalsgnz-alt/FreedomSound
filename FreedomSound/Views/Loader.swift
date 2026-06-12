//
//  Loader.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 04/05/2026.
//

import SwiftUI

struct InfinityLoader: View {
    @State private var start = Date.now

    let dotCount = 5
    let duration: TimeInterval = 1.55
    let width: CGFloat = 42
    let height: CGFloat = 24

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            let base = (elapsed.truncatingRemainder(dividingBy: duration)) / duration

            ZStack {
                ForEach(0..<dotCount, id: \.self) { i in
                    let p = (base - Double(i) * 0.045 + 1)
                        .truncatingRemainder(dividingBy: 1)

                    let t = p * .pi * 2
                    let x = width * sin(t)
                    let y = height * sin(t) * cos(t)

                    Circle()
                        .fill(color(at: p))
                        .frame(width: 10 * (1 - CGFloat(i) * 0.08),
                               height: 10 * (1 - CGFloat(i) * 0.08))
                        .opacity(1 - Double(i) * 0.14)
                        .blur(radius: 0.2)
                        .offset(x: x, y: y)
                }
            }
            .frame(width: 112, height: 72)
        }
    }

    private func color(at p: Double) -> Color {
        let colors: [(Double, Double, Double)] = [
            (255, 178, 54),
            (255, 122, 0),
            (255, 52, 35),
            (255, 178, 54)
        ]

        let scaled = p * Double(colors.count - 1)
        let i = min(Int(scaled), colors.count - 2)
        let t = scaled - Double(i)

        let a = colors[i]
        let b = colors[i + 1]

        return Color(
            red: (a.0 + (b.0 - a.0) * t) / 255,
            green: (a.1 + (b.1 - a.1) * t) / 255,
            blue: (a.2 + (b.2 - a.2) * t) / 255
        )
    }
}
