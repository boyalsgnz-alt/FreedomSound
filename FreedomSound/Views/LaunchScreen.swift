//
//  LaunchScreen.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 15/06/2026.
//

import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        VStack {
            Text("Freedom Sound")
            InfinityLoader()
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
