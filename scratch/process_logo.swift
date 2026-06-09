import Foundation
import Cocoa
import CoreGraphics

func processLogo() {
    let sourcePath = "/Users/seg/Desktop/Shemais/moharek_app/assets/logo.png"
    
    guard let image = NSImage(contentsOfFile: sourcePath) else {
        print("Error: Could not load source image from \(sourcePath)")
        exit(1)
    }
    
    guard let tiffData = image.tiffRepresentation,
          let imageSource = CGImageSourceCreateWithData(tiffData as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("Error: Could not get CGImage from source image")
        exit(1)
    }
    
    let width = cgImage.width
    let height = cgImage.height
    
    guard let colorSpace = cgImage.colorSpace,
          let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
        print("Error: Could not create context to inspect pixels")
        exit(1)
    }
    
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    guard let pixelData = context.data else {
        print("Error: Could not get pixel data context")
        exit(1)
    }
    
    let buffer = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
    
    var minX = width
    var maxX = 0
    var minY = height
    var maxY = 0
    
    for y in 0..<height {
        for x in 0..<width {
            let offset = (y * width + x) * 4
            let alpha = buffer[offset + 3]
            if alpha > 10 { // Non-transparent pixel threshold
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
    }
    
    print("Detected content bounding box: X(\(minX)..\(maxX)), Y(\(minY)..\(maxY))")
    
    if maxX <= minX || maxY <= minY {
        print("Error: Bounding box invalid (logo is completely transparent)")
        exit(1)
    }
    
    // Crop the image
    let cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    guard let croppedCgImage = cgImage.cropping(to: cropRect) else {
        print("Error: Failed to crop CGImage")
        exit(1)
    }
    
    // Create new 1024x1024 context
    let targetSize: CGFloat = 1024
    let targetRect = CGRect(x: 0, y: 0, width: targetSize, height: targetSize)
    
    guard let outputContext = CGContext(
        data: nil,
        width: Int(targetSize),
        height: Int(targetSize),
        bitsPerComponent: 8,
        bytesPerRow: Int(targetSize) * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        print("Error: Failed to create output context")
        exit(1)
    }
    
    // 1. Draw solid background color (Color #080B12)
    outputContext.setFillColor(red: 8.0/255.0, green: 11.0/255.0, blue: 18.0/255.0, alpha: 1.0)
    outputContext.fill(targetRect)
    
    // 2. Draw cropped logo centered, taking up 65% of the target size (standard and beautiful for app icons)
    let logoScale: CGFloat = 0.65
    let logoSize = targetSize * logoScale
    
    let cropWidth = CGFloat(croppedCgImage.width)
    let cropHeight = CGFloat(croppedCgImage.height)
    let cropAspect = cropWidth / cropHeight
    
    var drawWidth: CGFloat
    var drawHeight: CGFloat
    if cropAspect > 1.0 {
        drawWidth = logoSize
        drawHeight = logoSize / cropAspect
    } else {
        drawHeight = logoSize
        drawWidth = logoSize * cropAspect
    }
    
    let drawX = (targetSize - drawWidth) / 2.0
    let drawY = (targetSize - drawHeight) / 2.0
    let drawRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
    
    outputContext.draw(croppedCgImage, in: drawRect)
    
    // Save output to logo.png
    guard let finalCgImage = outputContext.makeImage() else {
        print("Error: Failed to create output image from context")
        exit(1)
    }
    
    let outputImage = NSImage(cgImage: finalCgImage, size: NSSize(width: targetSize, height: targetSize))
    guard let pngData = outputImage.tiffRepresentation?.bitmapImageRep?.representation(using: .png, properties: [:]) else {
        print("Error: Failed to generate PNG data")
        exit(1)
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: sourcePath))
        print("Success: Overwrote \(sourcePath) with cropped logo centered on themed background.")
    } catch {
        print("Error: Failed to write to file \(sourcePath): \(error)")
        exit(1)
    }
}

extension Data {
    var bitmapImageRep: NSBitmapImageRep? {
        return NSBitmapImageRep(data: self)
    }
}

processLogo()
