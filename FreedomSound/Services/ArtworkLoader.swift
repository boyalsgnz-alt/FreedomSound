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

    private let cache = NSCache<NSURL, NSData>()
    private let lock = NSLock()

    private struct TaskKey: Hashable {
        let url: URL
        let fullSize: Bool
    }
    private var runningTasks: [TaskKey: Task<UIImage?, Never>] = [:]

    func cachedImage(for url: URL, fullSize: Bool) -> UIImage? {
        guard let data = cache.object(forKey: url as NSURL) as Data? else { return nil }
        if fullSize { return UIImage(data: data) }
        return Self.downsampleArtwork(data: data, maxPixelSize: 120)
    }

    func loadArtwork(for url: URL, fullSize: Bool) -> Task<UIImage?, Never> {
        if let cachedData = cache.object(forKey: url as NSURL) as Data? {
                if fullSize { return Task { UIImage(data: cachedData) } }
                return Task { ArtworkLoader.downsampleArtwork(data: cachedData, maxPixelSize: 120) }
            }

        lock.lock()
        if let existing = runningTasks[TaskKey(url: url, fullSize: fullSize)] {
            lock.unlock()
            return existing
        }

        let task = Task(priority: .utility) { [weak self] () -> UIImage? in
            defer {
                self?.lock.withLock {
                    self?.runningTasks[TaskKey(url: url, fullSize: fullSize)] = nil
                }
            }
            guard let data = await Self.extractArtwork(from: url, fullSize: fullSize) as Data? else {
                return nil
            }
            self?.cache.setObject(data as NSData, forKey: url as NSURL)
            if fullSize {
                return UIImage(data: data)
            }
            return Self.downsampleArtwork(data: data, maxPixelSize: 120)
        }

        runningTasks[TaskKey(url: url, fullSize: fullSize)] = task
        lock.unlock()

        return task
    }

    private static func extractArtwork(from url: URL, fullSize: Bool) async -> NSData? {
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

            return artworkData as NSData
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
