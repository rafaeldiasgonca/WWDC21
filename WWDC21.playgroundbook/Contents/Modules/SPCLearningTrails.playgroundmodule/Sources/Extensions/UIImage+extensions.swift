//
//  UIImage+extensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

// MARK: - UIImage extensions

public extension UIImage {
    
    var isEmpty: Bool {
        return (size.width == 0) || (size.height == 0)
    }
    
    func scaledToFit(within availableSize: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth = availableSize.width / self.size.width
        let aspectHeight = availableSize.height / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: scaledImageRect.size, format: rendererFormat)
        let scaledImage = renderer.image { _ in
            self.draw(in: scaledImageRect)
        }
        return scaledImage
    }
    
    func scaledAndCroppedToMatchAspectRatio(of aspectSize: CGSize) -> UIImage {
        let aspectWidth = self.size.width  / aspectSize.width
        let aspectHeight = self.size.height / aspectSize.height
        let scalingFactor = min(aspectWidth, aspectHeight)
        let newSize = CGSize(width:  aspectSize.width  * scalingFactor,
                             height: aspectSize.height * scalingFactor)
        let drawRect = CGRect(origin: CGPoint(x: (newSize.width  - size.width)  / 2,
                                              y: (newSize.height - size.height) / 2),
                              size: size)
        
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: rendererFormat)
        let scaledImage = renderer.image { _ in
            self.draw(in: drawRect)
        }
        return scaledImage
    }

    func tinted(with color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        // flip the image
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -self.size.height)
        
        // multiply blend mode
        context.setBlendMode(.multiply)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context.fill(rect)
        
        // create UIImage
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func imageByApplyingClippingBezierPath(_ path: UIBezierPath, cropToPath: Bool = true) -> UIImage? {
        guard
            // Mask image using path.
            let maskedImage = imageByApplyingMaskingBezierPath(path)
            else { return nil }
        
        if cropToPath {
            // Crop image to frame of path.
            guard let croppedCGImage = maskedImage.cgImage?.cropping(to: path.bounds) else { return nil }
            return UIImage(cgImage: croppedCGImage)
        } else {
            return maskedImage
        }
    }
    
    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.saveGState()
        
        path.addClip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        context.restoreGState()
        UIGraphicsEndImageContext()
        
        return maskedImage
    }
    
    /// Returns a copy of the image overlaid with another image in the center.
    ///
    /// - Parameter overlayImage: The image to overlay.
    /// - Parameter offset: The amount by which to offset the overlay image from the center. Defaults to zero.
    ///
    /// - localizationKey: UIImage.overlaid(with:offsetBy:)
    func overlaid(with overlayImage: UIImage, offsetBy offset: CGPoint = CGPoint.zero) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        self.draw(at: CGPoint.zero)
        overlayImage.draw(at: CGPoint(x: (size.width / 2 - overlayImage.size.width / 2) + offset.x,
                                      y: (size.height / 2 - overlayImage.size.height / 2) + offset.y))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    func disabledImage(alpha: CGFloat) -> UIImage? {
        let context = CIContext(options: nil)
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        guard let output = filter.outputImage else { return nil }
        
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        let processedImage = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        return UIAccessibility.isReduceTransparencyEnabled ? processedImage : processedImage.imageWithAlpha(alpha: alpha)
    }
    
    func colorize(color: UIColor, blend: CGFloat) -> UIImage? {
        let context = CIContext(options: nil)
        let ciColor = CIColor(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent)
        guard let colorizeFilter = CIFilter(name: "CIColorMonochrome", parameters: [kCIInputImageKey : CIImage(image: self) as Any,
                                                                                    kCIInputColorKey : ciColor,
                                                                                    kCIInputIntensityKey : blend]) else { return nil }
        guard let colorizeOutput = colorizeFilter.outputImage else { return nil }
        guard let cgImage = context.createCGImage(colorizeOutput, from: colorizeOutput.extent) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
    
    func imageWithAlpha(alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /// Returns an image for text.
    ///
    /// - Parameter text: The placeholder text used to represent an image.
    ///
    /// - localizationKey: UIImage.image(text:)
    static func image(text: String, fontSize: CGFloat = 40) -> UIImage {
        let defaultSize = CGSize(width: 23, height: 27) // Default size for emoji with the chosen font and font size.
        let textColor: UIColor =  #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)
        
        let font = UIFont(name: "System0.00", size: CGFloat(fontSize)) ?? UIFont.systemFont(ofSize: CGFloat(fontSize))
        
        let sourceCharacter = text as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font : font, .foregroundColor: textColor]
        var textSize = sourceCharacter.size(withAttributes: attributes)
        if textSize.width < 1 || textSize.height < 1 {
            textSize = defaultSize
        }
        UIGraphicsBeginImageContextWithOptions(textSize, false, UIScreen.main.scale)
        sourceCharacter.draw(in: CGRect(x:0, y:0, width: textSize.width,  height: textSize.height), withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }

}

