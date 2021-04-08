import UIKit

public extension String {
    /// /*#-localizable-zone(stringExtension)*/Returns a SPCScene.Image from a string. Use to generate an image, based on an emoji string./*#-end-localizable-zone*/
    func image() -> Image {
        let size = CGSize(width: 80, height: 80)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 70)])
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return Image(with: image)
            
        } else {
            return Image(with: UIImage())
        }
    }
}
