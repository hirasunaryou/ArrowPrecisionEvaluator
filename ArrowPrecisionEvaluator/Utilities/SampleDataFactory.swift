import SwiftUI

enum SampleDataFactory {
    static func makePlaceholderImage(size: CGSize = CGSize(width: 900, height: 600)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemGray6.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.black.setStroke()
            let insetRect = CGRect(x: 80, y: 60, width: size.width - 160, height: size.height - 120)
            let path = UIBezierPath(rect: insetRect)
            path.lineWidth = 6
            path.stroke()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: paragraph
            ]

            let text = "Sample Target Image"
            let textRect = CGRect(x: 0, y: size.height / 2 - 24, width: size.width, height: 50)
            text.draw(in: textRect, withAttributes: attrs)
        }
    }

    static func makeSampleMarkerPoints() -> [MarkerPoint] {
        [
            MarkerPoint(xPx: 120, yPx: 120, xMm: 40, yMm: 30, areaPx: 55),
            MarkerPoint(xPx: 150, yPx: 160, xMm: 50, yMm: 40, areaPx: 60),
            MarkerPoint(xPx: 180, yPx: 140, xMm: 60, yMm: 35, areaPx: 58),
            MarkerPoint(xPx: 170, yPx: 190, xMm: 57, yMm: 48, areaPx: 63)
        ]
    }
}
