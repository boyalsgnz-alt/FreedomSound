//
//  SettingsView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI
import AVFoundation
import MediaPlayer

struct SettingsView: View {
    @EnvironmentObject var folderMgr: FolderManager
    @State private var showingFolderPicker = false
    
    var body: some View {
        VStack(){
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 8)
//            Spacer()
//            InfinityLoader()
//            Spacer()
            Grid(horizontalSpacing: 30, verticalSpacing: 30) {
                GridRow {
                    CountdownView()
                        .glassEffect(.regular.tint(Color(.sRGB, red: 215/255, green: 222/255, blue: 224/255, opacity: 0.5)).interactive(), in: .rect(cornerRadius: 16.0))
                    .aspectRatio(1, contentMode: .fit)
                    // .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .glassEffect(.regular.tint(Color.clear).interactive(), in: .rect(cornerRadius: 16.0))
                        .aspectRatio(1, contentMode: .fit)
                }
                
                GridRow {
                    Rectangle().fill(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .aspectRatio(1, contentMode: .fit)
                    
                    Rectangle().background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(8)
            Spacer()
            Button {
                showingFolderPicker.toggle()
            } label: {
                Label("Choose Folder", systemImage: "folder.badge.gearshape")
            }
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderPicker { url in
                folderMgr.savePickedFolder(url)
                showingFolderPicker = false
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/* #Preview {
    SettingsView()
}
*/
