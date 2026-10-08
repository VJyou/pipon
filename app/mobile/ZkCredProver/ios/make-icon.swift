// Regenerates MoproApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png from the logo:
// swift make-icon.swift ../../../verifier-demo/public/pipon-logo.png MoproApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png 0.86
// The logo is shrunk onto its own background colour so the rounded-corner mask does not clip the card.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// usage: make-icon <logo.png> <out.png> <scale>
let args = CommandLine.arguments
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil)!
let logo = CGImageSourceCreateImageAtIndex(src, 0, nil)!
let scale = Double(args[3])!
let size = 1024

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// Background: the logo's own corner pixel.
let probe = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: cs,
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
probe.draw(logo.cropping(to: CGRect(x: 4, y: 4, width: 1, height: 1))!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
let p = probe.data!.assumingMemoryBound(to: UInt8.self)
print("background rgb:", p[0], p[1], p[2])
ctx.setFillColor(CGColor(colorSpace: cs, components: [CGFloat(p[0]) / 255, CGFloat(p[1]) / 255, CGFloat(p[2]) / 255, 1])!)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let w = Double(size) * scale
let o = (Double(size) - w) / 2
ctx.interpolationQuality = .high
ctx.draw(logo, in: CGRect(x: o, y: o, width: w, height: w))

let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
