import Foundation
import UIKit
import CoreGraphics

/// Shared HSV segmentation pipeline used by both preview rendering and marker candidate detection.
enum HSVMarkerSegmentation {
    struct Component {
        let area: Int
        let centroidX: Double
        let centroidY: Double
    }

    struct Result {
        let width: Int
        let height: Int
        let mask: [UInt8]
        let components: [Component]
    }

    static func analyze(
        image: UIImage,
        preset: ColorPreset,
        parameters: SegmentationParameters
    ) -> Result? {
        guard let rgba = rgbaImage(from: image) else { return nil }
        let mask = buildMask(
            rgba: rgba,
            preset: preset,
            sensitivity: parameters.sensitivity
        )
        let components = connectedComponents(
            mask: mask,
            width: rgba.width,
            height: rgba.height,
            minArea: max(1, Int(parameters.minimumArea.rounded()))
        )

        return Result(
            width: rgba.width,
            height: rgba.height,
            mask: mask,
            components: components
        )
    }

    static func maskPreviewImage(from result: Result) -> UIImage? {
        let rgbaBytesPerPixel = 4
        let totalCount = result.width * result.height * rgbaBytesPerPixel
        var bytes = [UInt8](repeating: 0, count: totalCount)

        for idx in 0..<(result.width * result.height) {
            let maskValue = result.mask[idx]
            let base = idx * rgbaBytesPerPixel
            bytes[base] = maskValue      // R
            bytes[base + 1] = maskValue  // G
            bytes[base + 2] = maskValue  // B
            bytes[base + 3] = 255        // A
        }

        return makeUIImage(
            rgbaBytes: bytes,
            width: result.width,
            height: result.height
        )
    }
}

private extension HSVMarkerSegmentation {
    struct RGBAImage {
        let width: Int
        let height: Int
        let data: [UInt8]
    }

    struct HSVThresholds {
        let hueRanges: [(Double, Double)]
        let saturationMin: Double
        let saturationMax: Double
        let valueMin: Double
        let valueMax: Double
    }

    static func rgbaImage(from image: UIImage) -> RGBAImage? {
        guard let cgImage = normalizedCGImage(from: image) else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: &data,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return RGBAImage(width: width, height: height, data: data)
    }

    static func normalizedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cgImage = image.cgImage {
            return cgImage
        }

        let pixelWidth = Int(image.size.width * image.scale)
        let pixelHeight = Int(image.size.height * image.scale)
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pixelWidth, height: pixelHeight))
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: CGSize(width: pixelWidth, height: pixelHeight)))
        }
        return rendered.cgImage
    }

    static func buildMask(
        rgba: RGBAImage,
        preset: ColorPreset,
        sensitivity: Double
    ) -> [UInt8] {
        let thresholds = thresholds(for: preset, sensitivity: sensitivity)
        let pixelsCount = rgba.width * rgba.height
        var mask = [UInt8](repeating: 0, count: pixelsCount)

        for idx in 0..<pixelsCount {
            let base = idx * 4
            let r = Double(rgba.data[base]) / 255.0
            let g = Double(rgba.data[base + 1]) / 255.0
            let b = Double(rgba.data[base + 2]) / 255.0
            let hsv = rgbToHSV(r: r, g: g, b: b)

            let hueMatch = thresholds.hueRanges.contains { start, end in
                if start <= end {
                    return hsv.h >= start && hsv.h <= end
                }
                // Wrap-around interval (used by red near hue 0/1 boundary).
                return hsv.h >= start || hsv.h <= end
            }

            let matches =
                hueMatch &&
                hsv.s >= thresholds.saturationMin &&
                hsv.s <= thresholds.saturationMax &&
                hsv.v >= thresholds.valueMin &&
                hsv.v <= thresholds.valueMax

            mask[idx] = matches ? 255 : 0
        }

        return mask
    }

    /// Sensitivity mapping:
    /// - Higher sensitivity widens allowed hue range and relaxes sat/value lower bounds.
    /// - Lower sensitivity narrows hue and requires stronger, cleaner color.
    static func thresholds(for preset: ColorPreset, sensitivity: Double) -> HSVThresholds {
        let s = min(max(sensitivity, 0), 1)
        let hueHalfWidth = 0.03 + (0.10 * s)
        let saturationMin = max(0.10, 0.55 - (0.35 * s))
        let valueMin = max(0.05, 0.22 - (0.17 * s))
        let darkValueMax = min(0.35 + (0.35 * s), 0.80)
        let darkSatMax = min(0.40 + (0.40 * s), 0.95)

        switch preset {
        case .red:
            return HSVThresholds(
                hueRanges: [(1.0 - hueHalfWidth, hueHalfWidth)],
                saturationMin: saturationMin,
                saturationMax: 1.0,
                valueMin: valueMin,
                valueMax: 1.0
            )
        case .blue:
            return HSVThresholds(
                hueRanges: [(0.58 - hueHalfWidth, 0.58 + hueHalfWidth)],
                saturationMin: saturationMin,
                saturationMax: 1.0,
                valueMin: valueMin,
                valueMax: 1.0
            )
        case .green:
            return HSVThresholds(
                hueRanges: [(0.33 - hueHalfWidth, 0.33 + hueHalfWidth)],
                saturationMin: saturationMin,
                saturationMax: 1.0,
                valueMin: valueMin,
                valueMax: 1.0
            )
        case .yellow:
            return HSVThresholds(
                hueRanges: [(0.15 - hueHalfWidth, 0.15 + hueHalfWidth)],
                saturationMin: saturationMin,
                saturationMax: 1.0,
                valueMin: max(0.20, valueMin),
                valueMax: 1.0
            )
        case .black:
            // Black has no stable hue; use "very dark + low-ish saturation" gate.
            return HSVThresholds(
                hueRanges: [(0.0, 1.0)],
                saturationMin: 0.0,
                saturationMax: darkSatMax,
                valueMin: 0.0,
                valueMax: darkValueMax
            )
        }
    }

    static func connectedComponents(
        mask: [UInt8],
        width: Int,
        height: Int,
        minArea: Int
    ) -> [Component] {
        guard width > 0, height > 0 else { return [] }
        var visited = [Bool](repeating: false, count: width * height)
        var components: [Component] = []
        var queue = [Int]()
        queue.reserveCapacity(1024)

        let neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        for start in 0..<(width * height) where mask[start] > 0 && !visited[start] {
            visited[start] = true
            queue.removeAll(keepingCapacity: true)
            queue.append(start)

            var area = 0
            var sumX = 0.0
            var sumY = 0.0
            var head = 0

            while head < queue.count {
                let current = queue[head]
                head += 1

                let y = current / width
                let x = current % width
                area += 1
                sumX += Double(x)
                sumY += Double(y)

                for offset in neighbors {
                    let nx = x + offset.0
                    let ny = y + offset.1
                    guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                    let nIndex = ny * width + nx
                    if mask[nIndex] == 0 || visited[nIndex] { continue }
                    visited[nIndex] = true
                    queue.append(nIndex)
                }
            }

            guard area >= minArea else { continue }
            components.append(
                Component(
                    area: area,
                    centroidX: sumX / Double(area),
                    centroidY: sumY / Double(area)
                )
            )
        }

        return components.sorted { $0.area > $1.area }
    }

    static func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxValue = max(r, g, b)
        let minValue = min(r, g, b)
        let delta = maxValue - minValue
        let value = maxValue
        let saturation = maxValue == 0 ? 0 : delta / maxValue

        guard delta > .ulpOfOne else {
            return (0, saturation, value)
        }

        let hue: Double
        if maxValue == r {
            hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxValue == g {
            hue = ((b - r) / delta) + 2
        } else {
            hue = ((r - g) / delta) + 4
        }

        let normalizedHue = (hue / 6).truncatingRemainder(dividingBy: 1)
        return (normalizedHue >= 0 ? normalizedHue : normalizedHue + 1, saturation, value)
    }

    static func makeUIImage(rgbaBytes: [UInt8], width: Int, height: Int) -> UIImage? {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let data = Data(rgbaBytes)
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
