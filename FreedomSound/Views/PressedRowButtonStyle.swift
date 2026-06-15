//
//  PressedRowButtonStyle.swift
//  FreedomSound
//
//  Created by Codex on 12/06/2026.
//

import SwiftUI

struct RowButton<Content: View>: View {
    let minHeight: CGFloat
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var isTapped = false

    var body: some View {
        Button {
            isTapped = true

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(90))
                action()
                try? await Task.sleep(for: .milliseconds(90))
                isTapped = false
            }
        } label: {
            content()
                .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .overlay {
                    Rectangle()
                        .fill(Color.white.opacity(isTapped ? 0.15 : 0))
                        .allowsHitTesting(false)
                }
                .background(.red.opacity(0.2))
        }
        .buttonStyle(.plain)
        .animation(.easeIn(duration: 0.01), value: isTapped)
        .animation(.easeOut(duration: 0.01), value: isTapped)
    }
}
