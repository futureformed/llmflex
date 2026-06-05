import AppKit
import SwiftUI

/// The LLM Flex mark — a filled node, a connecting line, and an outline node:
/// "switch one model for another". Drawn directly from the brand `menubar.svg`
/// geometry (viewBox 32×18) so it stays crisp at any size without bundling an
/// SVG/PNG. Produced as a *template* image (black on clear) so the menu bar
/// tints it for light/dark automatically; tint it explicitly in-app with
/// `.foregroundStyle`.
enum BrandGlyph {
    /// Render the mark at the given point height. Width follows the 32:18
    /// aspect ratio of the source artwork.
    static func image(height: CGFloat) -> NSImage {
        let vbW: CGFloat = 32, vbH: CGFloat = 18
        let s = height / vbH
        let size = NSSize(width: vbW * s, height: vbH * s)

        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            NSColor.black.setStroke()

            // Filled node — cx 6.5, cy 9, r 5.
            NSBezierPath(ovalIn: NSRect(x: (6.5 - 5) * s, y: (9 - 5) * s,
                                        width: 10 * s, height: 10 * s)).fill()

            // Connecting line — (11.5,9)→(20.5,9), round caps.
            let line = NSBezierPath()
            line.move(to: NSPoint(x: 11.5 * s, y: 9 * s))
            line.line(to: NSPoint(x: 20.5 * s, y: 9 * s))
            line.lineWidth = 2.4 * s
            line.lineCapStyle = .round
            line.stroke()

            // Outline node — cx 25.5, cy 9, r 5, stroke 2.4.
            let ring = NSBezierPath(ovalIn: NSRect(x: (25.5 - 5) * s, y: (9 - 5) * s,
                                                   width: 10 * s, height: 10 * s))
            ring.lineWidth = 2.4 * s
            ring.stroke()

            return true
        }
        image.isTemplate = true
        return image
    }

    /// Menu-bar status item glyph. 16pt tall reads cleanly in the menu bar and
    /// macOS tints the template for the current appearance.
    static let menuBar = image(height: 16)
}
