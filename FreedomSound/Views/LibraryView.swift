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
        VStack(spacing: 0) {
            Text("Your library")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()

            List {
                RowButton(minHeight: 34) {
                    router.goToViewTester()
                } content: {
                    HStack(spacing: 12) {
                        Text("All Songs")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                RowButton(minHeight: 34) {
                    router.goToPlaylists()
                } content: {
                    HStack(spacing: 12) {
                        Text("Playlists")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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
