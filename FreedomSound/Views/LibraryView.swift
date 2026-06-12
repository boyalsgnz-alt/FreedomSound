//
//  LibraryView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI

struct LibraryView: View {
    @State private var showingFolderPicker = false
    @EnvironmentObject var manager: FolderAccessManager
    @EnvironmentObject var router: Router
    
    var body: some View {
        VStack {
            Text("Your library")
                .font(.title)
                .padding(.top, 8)
            List() {
                Button {
                    router.goToViewTester()
                } label: {
                    HStack {
                        Text("All Songs")
                        Spacer()
                        Text(">")
                    }
                }
                .buttonStyle(.plain)

                Button {
                    router.goToPlaylists()
                } label: {
                    HStack {
                        Text("Playlists")
                        Spacer()
                        Text(">")
                    }
                }
                .buttonStyle(.plain)
                /* Button {
                    print("Row clicked")
                    showingFolderPicker = true
                } label: {
                    HStack {
                        Text("Open folder")
                        Spacer()
                        Text(">")
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain) */
            }
            .listStyle(.plain)
            .sheet(isPresented: $showingFolderPicker) {
                FolderPicker { url in
                    manager.savePickedFolder(url)
                    manager.scanFolder()
                    showingFolderPicker = false
                }
            }
        }
    }
}

#Preview {
    LibraryView()
}
