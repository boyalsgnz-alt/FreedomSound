//
//  KMeans.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 22/06/2026.
//

import UIKit
import Accelerate

struct KMeansColorExtractor {
    
    // MARK: - Types
    struct RGBPoint {
        var r, g, b: Float
    }
    
    // MARK: - Public API
    static func extract(from image: UIImage, colorCount k: Int = 3, iterations: Int = 10) -> [UIColor] {
        guard let pixels = samplePixels(from: image) else { return [.gray] }
        
        var centroids = initCentroids(from: pixels, k: k)
        var assignments = [Int](repeating: 0, count: pixels.count)
        
        for _ in 0..<iterations {
            // Étape 1 : assigner chaque pixel au centroïde le plus proche
            var changed = false
            for i in 0..<pixels.count {
                let nearest = nearestCentroid(for: pixels[i], centroids: centroids)
                if assignments[i] != nearest { changed = true }
                assignments[i] = nearest
            }
            guard changed else { break }  // convergence atteinte
            
            // Étape 2 : recalculer les centroïdes
            centroids = recomputeCentroids(pixels: pixels, assignments: assignments, k: k)
        }
        
        return centroids.map { UIColor(red: CGFloat($0.r), green: CGFloat($0.g), blue: CGFloat($0.b), alpha: 1) }
    }
    
    // MARK: - Internals
    private static func samplePixels(from image: UIImage, size: Int = 64) -> [RGBPoint]? {
        let targetSize = CGSize(width: size, height: size)
        UIGraphicsBeginImageContext(targetSize)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = resized?.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }
        
        var pixels: [RGBPoint] = []
        let width = cgImage.width
        let height = cgImage.height
        let bpp = cgImage.bitsPerPixel / 8
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * cgImage.bytesPerRow + x * bpp
                let r = Float(bytes[offset])     / 255
                let g = Float(bytes[offset + 1]) / 255
                let b = Float(bytes[offset + 2]) / 255
                // Ignorer pixels trop sombres / trop clairs
                let brightness = (r + g + b) / 3
                guard brightness > 0.08 && brightness < 0.92 else { continue }
                pixels.append(RGBPoint(r: r, g: g, b: b))
            }
        }
        return pixels
    }
    
    private static func initCentroids(from pixels: [RGBPoint], k: Int) -> [RGBPoint] {
        // K-means++ : chaque nouveau centroïde est choisi
        // avec une probabilité proportionnelle à sa distance au plus proche centroïde existant
        var centroids: [RGBPoint] = [pixels.randomElement()!]
        
        while centroids.count < k {
            let distances = pixels.map { p -> Float in
                let d = nearestDistance(for: p, centroids: centroids)
                return d * d
            }
            let total = distances.reduce(0, +)
            var pick = Float.random(in: 0..<total)
            for (i, d) in distances.enumerated() {
                pick -= d
                if pick <= 0 { centroids.append(pixels[i]); break }
            }
        }
        return centroids
    }
    
    private static func nearestCentroid(for point: RGBPoint, centroids: [RGBPoint]) -> Int {
        var best = 0
        var bestDist = Float.greatestFiniteMagnitude
        for (i, c) in centroids.enumerated() {
            let d = distance(point, c)
            if d < bestDist { bestDist = d; best = i }
        }
        return best
    }
    
    private static func nearestDistance(for point: RGBPoint, centroids: [RGBPoint]) -> Float {
        centroids.map { distance(point, $0) }.min() ?? 0
    }
    
    private static func distance(_ a: RGBPoint, _ b: RGBPoint) -> Float {
        let dr = a.r - b.r, dg = a.g - b.g, db = a.b - b.b
        return dr*dr + dg*dg + db*db  // distance euclidienne au carré (évite sqrt inutile)
    }
    
    private static func recomputeCentroids(pixels: [RGBPoint], assignments: [Int], k: Int) -> [RGBPoint] {
        var sums = [(r: Float, g: Float, b: Float, count: Int)](repeating: (0,0,0,0), count: k)
        for (i, p) in pixels.enumerated() {
            let c = assignments[i]
            sums[c].r += p.r; sums[c].g += p.g; sums[c].b += p.b; sums[c].count += 1
        }
        return sums.map { s in
            guard s.count > 0 else { return pixels.randomElement()! }
            return RGBPoint(r: s.r / Float(s.count), g: s.g / Float(s.count), b: s.b / Float(s.count))
        }
    }
}
