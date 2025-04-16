//
//  UI+Extensions.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 3/6/25.
//

import Foundation
import UIKit

internal extension UIView {
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        layer.mask = shapeLayer
    }
}

internal extension UIColor {
    // HEX 문자열을 UIColor로 변환하는 함수
    convenience init(hex: String) {
        
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                
        // #이 포함되어 있으면 제거
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        // 길이가 6이면 RGB, 8이면 RGBA
        let length = hexSanitized.count
        guard length == 6 || length == 8 else {
            self.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            return
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgbValue)
        
        let r, g, b, a: CGFloat
        if length == 6 {
            r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgbValue & 0x0000FF) / 255.0
            a = 1.0 // 알파값 없음 → 기본값 1.0
        } else {
            r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgbValue & 0x000000FF) / 255.0
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
        
//
//        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
//        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
//
//        var rgb: UInt64 = 0
//        Scanner(string: hexSanitized).scanHexInt64(&rgb)
//
//        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
//        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
//        let blue = CGFloat(rgb & 0x0000FF) / 255.0
//
//        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

internal extension UIImage {
    // UIColor를 UIImage로 변환하는 익스텐션
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

class PaddedLabel: UILabel {
    var padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

    override func drawText(in rect: CGRect) {
        let paddedRect = rect.inset(by: padding)
        super.drawText(in: paddedRect)
    }
}
