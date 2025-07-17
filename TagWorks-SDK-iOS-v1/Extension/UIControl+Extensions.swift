//
//  UIControl+Extensions.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 5/20/25.
//

import Foundation
import UIKit
import ObjectiveC

internal extension UIControl {
    
    // 스위즐링(Swizzling)은 런타임에 클래스의 메서드 구현을 교체하는 기법
    // Objective-C의 런타임 특성을 활용
    static func swizzleSendAction() {
        let cls = UIControl.self
        let original = #selector(UIControl.sendAction(_:to:for:))
        let swizzled = #selector(UIControl.swizzled_sendAction(_:to:for:))

        guard let originalMethod = class_getInstanceMethod(cls, original),
              let swizzledMethod = class_getInstanceMethod(cls, swizzled) else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc func swizzled_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        
        // 원래 동작 수행
        self.swizzled_sendAction(action, to: target, for: event)
        
//        if let button = self as? UIButton, TagWorks.sharedInstance.isRegistered(button) {
        if let button = self as? UIButton {
            
            SwizzlingManager.sharedInstance.buttonClickSwizzle(button, event: event)
            
//            let title = button.title(for: .normal) ?? "(no title)"
//            print("🔍 버튼 클릭 감지: title: \(title)")
//            print("👆 버튼 클릭: \(button)")
//            
//            let dataBundle = DataBundle()
//            dataBundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.CLICK)
//            dataBundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, title)
//            let _ = TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_USER_EVENT, bundle: dataBundle)
        }
    }
}
