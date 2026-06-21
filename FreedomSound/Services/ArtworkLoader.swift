//
//  ArtworkLoader.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 12/04/2026.
//

import UIKit
import AVFoundation
import ImageIO

final class ArtworkLoader {
    static let shared = ArtworkLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private var runningTasks: [URL: Task<UIImage?, Never>] = [:]
    private let lock = NSLock()

    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func loadArtwork(for url: URL, fullSize: Bool) -> Task<UIImage?, Never> {
        if let cached = cache.object(forKey: url as NSURL), !fullSize {
            return Task { cached }
        }

        lock.lock()
        if let existing = runningTasks[url] {
            lock.unlock()
            return existing
        }

        let task = Task(priority: .utility) { [weak self] () -> UIImage? in
            defer {
                self?.lock.withLock {
                    self?.runningTasks[url] = nil
                }
            }

            let image = await Self.extractArtwork(from: url, fullSize: fullSize)
            if let image {
                self?.cache.setObject(image, forKey: url as NSURL)
            }
            return image
        }

        runningTasks[url] = task
        lock.unlock()

        return task
    }

    private static func extractArtwork(from url: URL, fullSize: Bool) async -> UIImage? {
        let asset = AVURLAsset(url: url)

        do {
            let metadata = try await asset.load(.commonMetadata)

            guard let artworkData = AVMetadataItem.metadataItems(
                from: metadata,
                withKey: AVMetadataKey.commonKeyArtwork,
                keySpace: .common
            ).first?.dataValue else {
                return nil
            }

            if fullSize {
                return UIImage(data: artworkData)
            }
            return downsampleArtwork(data: artworkData, maxPixelSize: 120)
        } catch {
            print("Artwork load failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func downsampleArtwork(data: Data, maxPixelSize: Int) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary

        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
