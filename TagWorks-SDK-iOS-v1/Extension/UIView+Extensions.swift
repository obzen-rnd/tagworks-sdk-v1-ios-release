//
//  UIView+Extensions.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 5/16/25.
//

import Foundation
import UIKit
import ObjectiveC

internal extension UIView {
    
    // 해당 뷰가 속해 있는 ViewController를 리턴
    var viewController: UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }
        return nil
    }
    
    // UIView에 roundRadius를 적용
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
    
    ///
    /// 스위즐링 Part
    ///
    // MARK: 감지 여부 저장용 Associated Object
    private struct AssociatedKeys {
        static var hasTrackedKey : UInt8 = 0
    }

    var hasTrackedAppear: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.hasTrackedKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.hasTrackedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: 실제로 화면에 보이는지 계산
    var isVisibleOnScreen: Bool {
        guard let window = self.window else { return false }
        if self.isHidden || self.alpha < 0.01 || self.bounds.isEmpty {
            return false
        }
        let frameInWindow = self.convert(self.bounds, to: window)
        return window.bounds.intersects(frameInWindow)
    }

    // MARK: - Swizzling
    static func swizzleDidMoveToWindowForTracking() {
        let originalSelector = #selector(UIView.didMoveToWindow)
        let swizzledSelector = #selector(UIView.swizzled_didMoveToWindow)

        guard let originalMethod = class_getInstanceMethod(UIView.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIView.self, swizzledSelector) else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    // MARK: - 교체될 메서드
    @objc private func swizzled_didMoveToWindow() {
        // 원래 동작 유지
        swizzled_didMoveToWindow()

        // 시스템 뷰 무시 (필터링)
//            let systemViewPrefixes = ["_", "UI", "WK"]
        let systemViewPrefixes = ["_", "UI"]
        let className = NSStringFromClass(type(of: self))
        let isSystemView = systemViewPrefixes.contains { className.hasPrefix($0) }
        guard !isSystemView else { return }

        // 이미 추적한 경우는 무시
            if hasTrackedAppear || window == nil {
                if window == nil {
                    hasTrackedAppear = false // 화면에서 사라졌다면 다시 감지할 수 있도록 초기화
                }
                return
            }

            // 다음 RunLoop에서 확인 (실제로 보이는지 체크)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !self.hasTrackedAppear, self.window != nil, self.isVisibleOnScreen {
                    self.hasTrackedAppear = true
                    print("📸 View appeared: \(type(of: self))")
                }
            }
    }
}


