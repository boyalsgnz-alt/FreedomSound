//
//  LibraryScanner.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/06/2026.
//

import Foundation
import UniformTypeIdentifiers

final class LibraryScanner {
    
    /**
     This function scans the folder passed as parameter and returns both .m3u and .mp3 files as URLs
     Param: folderUrl -> URL. The folder to scan
     */
    func scanFolder(folderUrl: URL?) throws -> [URL]? {
        if folderUrl == nil {
            return nil
        }
        
        guard let enumerator = FileManager.default.enumerator(
            at: folderUrl!,
            includingPropertiesForKeys: [.contentTypeKey, .nameKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
        ) else {
            throw NSError(
                domain: "FolderAccessManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not enumerate folder."]
            )
        }
        
        var hits: [URL] = []
        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: [.contentTypeKey, .nameKey])
                
                if let contentType = values.contentType {
                    if contentType.conforms(to: .audio) {
                        hits.append(fileURL)
                    }
                    else {
                        let ext = fileURL.pathExtension.lowercased()
                        if (ext.starts(with: "m3u")) {
                            hits.append(fileURL)
                        }
                    }
                }
            } catch {
                print("Skipping unreadable item:", fileURL.lastPathComponent, "error:", error)
            }
        }
        return hits
    }
}
