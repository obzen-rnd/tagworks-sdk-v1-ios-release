//
//  UIViewController+Extensions.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 5/16/25.
//

import Foundation
import UIKit

/// 스위즐링을 이용한 메서드 후킹 (메소드 교체)
extension UIViewController {
    
    private static var originalIMPs: [Selector: IMP] = [:]
    
    // 스위즐링 인터페이스
    static func swizzleVCLifecycle() {
        
        let cls: AnyClass = UIViewController.self
        // 스위즐링 하고자 하는 메서드만 옵션처리
        let swizzleFlag: [String: Bool] = ["viewDidLoad": false,
                                           "viewWillAppear": false,
                                           "viewDidAppear": true,
                                           "viewWillDisappear": false,
                                           "viewDidDisappear": false]
//        DispatchQueue.main.async {
//        }
        
        // viewDidLoad (파라미터 없음)
        if swizzleFlag["viewDidLoad"]! {
            
            SwizzlingManager.sharedInstance.injectSwizzling(
                in: cls,
                selector: #selector(UIViewController.viewDidLoad)) { target, sel in

                let vcClass: AnyClass = type(of: target)
                if vcClass == UINavigationController.self { return }
                let bundle = Bundle(for: vcClass)
                if bundle == Bundle.main {
                    SwizzlingManager.sharedInstance.viewControllerSwizzle(target as! UIViewController, "viewDidLoad")
                }
            }
        }
        
        // viewWillAppear(_ animated: Bool)
        if swizzleFlag["viewWillAppear"]! {
            
            SwizzlingManager.sharedInstance.injectSwizzlingForBool(
                in: cls,
                selector: #selector(UIViewController.viewWillAppear(_:))) { target, sel, animated in
    //            print("[SDK] \(type(of: target)) - viewWillAppear(animated: \(animated))")
                
                let vcClass: AnyClass = type(of: target)
                if vcClass == UINavigationController.self { return }
                let bundle = Bundle(for: vcClass)
                if bundle == Bundle.main {
                    SwizzlingManager.sharedInstance.viewControllerSwizzle(target as! UIViewController, "viewWillAppear")
                }
            }
        }
        
        // viewDidAppear(_ animated: Bool)
        if swizzleFlag["viewDidAppear"]! {
            
            SwizzlingManager.sharedInstance.injectSwizzlingForBool(
                in: cls,
                selector: #selector(UIViewController.viewDidAppear(_:))) { target, sel, animated in
                
                let vcClass: AnyClass = type(of: target)
                if vcClass == UINavigationController.self { return }
                let bundle = Bundle(for: vcClass)
                if bundle == Bundle.main {
                    SwizzlingManager.sharedInstance.viewControllerSwizzle(target as! UIViewController, "viewDidAppear")
                }
            }
        }
        
        // viewWillDisappear(_ animated: Bool)
        if swizzleFlag["viewWillDisappear"]! {
            
            SwizzlingManager.sharedInstance.injectSwizzlingForBool(
                in: cls,
                selector: #selector(UIViewController.viewWillDisappear(_:))) { target, sel, animated in
                
                let vcClass: AnyClass = type(of: target)
                if vcClass == UINavigationController.self { return }
                let bundle = Bundle(for: vcClass)
                if bundle == Bundle.main {
                    SwizzlingManager.sharedInstance.viewControllerSwizzle(target as! UIViewController, "viewWillDisappear")
                }
            }
        }
        
        // viewDidDisappear(_ animated: Bool)
        if swizzleFlag["viewDidDisappear"]! {
            
            SwizzlingManager.sharedInstance.injectSwizzlingForBool(
                in: cls,
                selector: #selector(UIViewController.viewDidDisappear(_:))) { target, sel, animated in
                
                let vcClass: AnyClass = type(of: target)
                let bundle = Bundle(for: vcClass)
                if bundle == Bundle.main {
                    SwizzlingManager.sharedInstance.viewControllerSwizzle(target as! UIViewController, "viewDidDisappear")
                }
            }
        }
        
        

        
        
        
        
//        let cls: AnyClass = UIViewController.self
//
//        // 스위즐링을 할 라이프사이클 메소드만 설정
//        let swizzlingPairs: [(Selector, Selector)] = [
////            (#selector(UIViewController.viewDidLoad), #selector(UIViewController.tagworks_viewDidLoad)),
//
//            (#selector(UIViewController.viewWillAppear(_:)), #selector(UIViewController.tagworks_viewWillAppear(_:))),
//            (#selector(UIViewController.viewDidAppear(_:)), #selector(UIViewController.tagworks_viewDidAppear(_:))),
//            (#selector(UIViewController.viewDidDisappear(_:)), #selector(UIViewController.tagworks_viewDidDisappear(_:))),
//
////            (#selector(UIViewController.viewWillLayoutSubviews), #selector(UIViewController.tagworks_viewWillLayoutSubviews)),
//
////            (#selector(UIViewController.present(_:animated:completion:)), #selector(UIViewController.tagworks_present(_:animated:completion:))),
////            (#selector(UIViewController.dismiss(animated:completion:)), #selector(UIViewController.tagworks_dismiss(animated:completion:))),
////
////            (#selector(setter: UIViewController.view), #selector(UIViewController.tagworks_setView(_:))),       // UIViewController의 view가 새로운 view로 교체될 때.
//        ]
//
//        for (originalSel, swizzledSel) in swizzlingPairs {
//            // 인스턴스 메소드를 가져옴
//            guard let method = class_getInstanceMethod(cls, originalSel) else { continue }
//
//            // 원래 구현 (또는 이전에 누가 스위즐링한 구현 - 함수 포인터를 가져옴)
//            let currentIMP = method_getImplementation(method)
//
//            // 중복 방지 없으면 원래 함수 포인터를 저장
//            if originalIMPs[originalSel] != nil { return }
//            originalIMPs[originalSel] = currentIMP
//
//            // tagworks의 새 구현을 생성
//            // 라이프 사이클 중 파라미터가 Bool 하나인 경우, (viewWillAppear(), viewDidAppear(), viewWillDisappear(), viewDidDisappear())
//            let block: @convention(block) (UIViewController, Bool) -> Void = { vc, animated in
//                // 🔹 내가 원하는 동작 수행
//                let vcClass: AnyClass = type(of: vc)
//                if vcClass == UINavigationController.self { return }
//
//                let bundle = Bundle(for: vcClass)
//                if bundle == Bundle.main {
//                    var event: String = ""
//                    if originalSel == #selector(UIViewController.viewWillAppear(_:)) {
//                        event = "viewWillAppear"
//                    } else if originalSel == #selector(UIViewController.viewDidAppear(_:)) {
//                        event = "viewDidAppear"
//                    } else if originalSel == #selector(UIViewController.viewDidDisappear(_:)) {
//                        event = "viewDidDisappear"
//                    }
//                    print("🍎[TagWorks v\(CommonUtil.getSDKVersion()!)] \(event): \(type(of: vc))")
//                }
//
//
//                // 🔹 이전 구현 호출 (원래 구현 또는 다른 SDK의 구현)
//                if let imp = originalIMPs[originalSel] {
//                    typealias Func = @convention(c) (UIViewController, Selector, Bool) -> Void
//                    let fn = unsafeBitCast(imp, to: Func.self)
//                    fn(vc, originalSel, animated)
//                }
//            }
//
//            let newIMP = imp_implementationWithBlock(block)
//            method_setImplementation(method, newIMP)
//
//
//
////            // 기본적인 스위즐링 코드
////            // 인스턴스 메소드를 가져옴
////            guard let originalMethod = class_getInstanceMethod(cls, originalSel),
////                  let swizzledMethod = class_getInstanceMethod(cls, swizzledSel) else {
////                continue
////            }
////
////            // 두 개의 메소드를 교체
////            method_exchangeImplementations(originalMethod, swizzledMethod)
//        }
    }
    
    
    
    
//    @objc public func tagworks_viewWillLayoutSubviews() {
//        // Call original
//        self.tagworks_viewWillLayoutSubviews()
//        
//        // Custom logic
//        // 시스템이 아닌, 앱 내 번들에 포함된 ViewController만 추적
////        let className = String(describing: type(of: self))
//        let vcClass: AnyClass = type(of: self)
//        let bundle = Bundle(for: vcClass)
//
//        if bundle == Bundle.main {
//            SwizzlingManager.sharedInstance.track(self, "viewWillLayoutSubviews")
////            print("🔍 화면 진입 감지: \(className)")
//        }
//    }
//    
//    @objc public func tagworks_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
//        // Call original
//        self.tagworks_present(viewControllerToPresent, animated:flag, completion: completion)
//        
//        // Custom logic
//        // 시스템이 아닌, 앱 내 번들에 포함된 ViewController만 추적
////        let className = String(describing: type(of: self))
//        let vcClass: AnyClass = type(of: viewControllerToPresent)
//        let bundle = Bundle(for: vcClass)
//
//        if bundle == Bundle.main {
//            SwizzlingManager.sharedInstance.track(viewControllerToPresent, "present")
////            print("🔍 화면 진입 감지: \(className)")
//        }
//    }
//    
//    @objc public func tagworks_dismiss(animated: Bool, completion: (() -> Void)? = nil) {
//        // Call original
//        self.tagworks_dismiss(animated: animated, completion: completion)
//        
//        // Custom logic
//        // 시스템이 아닌, 앱 내 번들에 포함된 ViewController만 추적
////        let className = String(describing: type(of: self))
//        let vcClass: AnyClass = type(of: self.presentedViewController!)
//        let bundle = Bundle(for: vcClass)
//
//        if bundle == Bundle.main {
//            SwizzlingManager.sharedInstance.track(self.presentedViewController!, "dismiss")
////            print("🔍 화면 진입 감지: \(className)")
//        }
//    }
//    
//    @objc func tagworks_setView(_ view: UIView?) {
//        print("[Swizzled] \(self) will set new view: \(String(describing: view))")
//
//        // Call original setView(_:) (now swizzled)
////        swizzled_setView(view)
//    }


    
    


    // 1. 스위즐링 메서드 등록 (앱 시작 시 딱 1번 실행)
//    static func swizzleLifecyclee() {
//        let originalSelector = #selector(viewDidAppear(_:))
//        let swizzledSelector = #selector(swizzled_viewDidAppear(_:))
//
//        guard let originalMethod = class_getInstanceMethod(self, originalSelector),
//              let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else {
//            return
//        }
//
//        method_exchangeImplementations(originalMethod, swizzledMethod)
//    }
//
//    // 2. 스위즐링된 메서드 구현
//    @objc func swizzled_viewDidAppear(_ animated: Bool) {
//        // 원래 viewDidAppear 실행 (사실은 스위즐링 덕분에 이게 원래 코드임)
//        self.swizzled_viewDidAppear(animated)
//
////        // 제외할 ViewController 클래스 이름 목록 (키보드, 텍스트 입력 관련 ViewController)
////        let ignoredViewControllers: Set<String> = [
////            "UICompatibilityInputViewController",
////            "UIInputWindowController",
////            "UISystemInputAssistantViewController",
////            "UIPredictionViewController",
////            "UISystemKeyboardDockController",
////            "PrewarmingViewController",
////            "_UICursorAccessoryViewController"
////        ]
//        
////        // 이벤트 출력을 하고자 원하는 ViewController 클래스 이름 목록
////        let ignoredViewControllers: Set<String> = [
////            "WebPopupViewController"
////        ]
////
////        // 원하는 추적 로직
////        let className = String(describing: type(of: self))
////        if ignoredViewControllers.contains(className) {
////            print("🔍 화면 진입 감지: \(className)")
////        }
//        
//        
//        // 시스템이 아닌, 앱 내 번들에 포함된 ViewController만 추적
//        let className = String(describing: type(of: self))
//        let vcClass: AnyClass = type(of: self)
//        let bundle = Bundle(for: vcClass)
//
//        if bundle == Bundle.main {
////            ViewControllerTracker.shared.markAppeared(vc: vcClass)
//            print("🔍 화면 진입 감지: \(className)")
//        }
//    }
}

///
/// ViewController 관련 유틸
extension UIViewController {
    
    // 내가 현재 보고 있는 ViewController 클래스를 리턴
    static func topViewController(base: UIViewController? = {
        if #available(iOS 13.0, *) {
            // iOS 13 이상: Scene 기반으로 keyWindow 가져오기
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        } else {
            // iOS 12 이하
            return UIApplication.shared.keyWindow?.rootViewController
        }
    }()) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
    
    // 현재 내가 보고 있는 ViewController의 경로를 배열로 리턴
    static func viewControllerPath(from root: UIViewController? = {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        } else {
            return UIApplication.shared.keyWindow?.rootViewController
        }
    }()) -> [UIViewController] {
        
        guard let root = root else { return [] }
        var path: [UIViewController] = []
        
        var current: UIViewController? = root
        
        while let vc = current {
            path.append(vc)
            
            if let nav = vc as? UINavigationController {
                // Push된 전체 스택을 추가
                let stack = nav.viewControllers
                if stack.count > 1 {
//                    path.append(contentsOf: stack.dropFirst()) // 중복 루트 제거
                    path.append(contentsOf: stack.dropLast()) // 중복 루트 제거
                }
                current = nav.visibleViewController
            } else if let tab = vc as? UITabBarController,
                      let selected = tab.selectedViewController {
                current = selected
            } else if let presented = vc.presentedViewController {
                current = presented
            } else {
                break
            }
        }
        
        return path
    }
    
    static func viewControllerPathDescription() -> String {
        let path = UIViewController.viewControllerPath()
        
        guard !path.isEmpty else {
            return ""
        }
        
        // 클래스 이름 추출
        let names = path.map { String(describing: type(of: $0)) }
        
        // " / " 로 연결
        return names.joined(separator: "/")
    }
}

@available(iOS 13.0, *)
extension UIWindowScene {
    var keyWindow: UIWindow? {
        return self.windows.first(where: { $0.isKeyWindow })
    }
}
