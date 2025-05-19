//
//  UIViewController+Extensions.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 5/16/25.
//

import Foundation
import UIKit

/// 스위즐링을 이용한 메서드 후킹 (재구성)
internal extension UIViewController {

    // 1. 스위즐링 메서드 등록 (앱 시작 시 딱 1번 실행)
    static func swizzleLifecycle() {
        let originalSelector = #selector(viewDidAppear(_:))
        let swizzledSelector = #selector(swizzled_viewDidAppear(_:))

        guard let originalMethod = class_getInstanceMethod(self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    // 2. 스위즐링된 메서드 구현
    @objc func swizzled_viewDidAppear(_ animated: Bool) {
        // 원래 viewDidAppear 실행 (사실은 스위즐링 덕분에 이게 원래 코드임)
        self.swizzled_viewDidAppear(animated)

//        // 제외할 ViewController 클래스 이름 목록 (키보드, 텍스트 입력 관련 ViewController)
//        let ignoredViewControllers: Set<String> = [
//            "UICompatibilityInputViewController",
//            "UIInputWindowController",
//            "UISystemInputAssistantViewController",
//            "UIPredictionViewController",
//            "UISystemKeyboardDockController",
//            "PrewarmingViewController",
//            "_UICursorAccessoryViewController"
//        ]
        
        // 이벤트 출력을 하고자 원하는 ViewController 클래스 이름 목록
        let ignoredViewControllers: Set<String> = [
            "WebPopupViewController"
        ]

        // 원하는 추적 로직
        let className = String(describing: type(of: self))
        if ignoredViewControllers.contains(className) {
            print("🔍 화면 진입 감지: \(className)")
        }
        
//        // 원하는 추적 로직
//        let screenName = String(describing: type(of: self))
//        print("🔍 화면 진입 감지: \(screenName)")

        // 분석 SDK로 이벤트 전송 가능
//        EventCollector.shared.track(event: "screenView", metadata: ["screen": screenName])
    }
}
