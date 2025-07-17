//
//  SwizzlingManager.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 5/30/25.
//

import Foundation
import UIKit

/// Swizzling 관리
public final class SwizzlingManager {
    
    public static let sharedInstance = SwizzlingManager()
    
    private init() {}
    
    private var didSwizzle = false
    private var originalIMPs: [String: IMP] = [:]
    
    // 스위즐링 트랙킹 시작
    public func lifecycleTracking() {
        guard !didSwizzle else { return }
        didSwizzle = true
        
        
        UIViewController.swizzleVCLifecycle()
        Application.initializeApplicationTracking()
//        UIControl.swizzleSendAction()
    }
    
    
    // UIViewController Lifecycle 스위즐링 시 실행 코드
    func viewControllerSwizzle(_ vc: UIViewController, _ event: String) {
        // 화면 전환 수집을 자동 수집으로 설정했을 때
        if TagWorks.sharedInstance.autoTrackingPage &&
            !TagWorks.sharedInstance.isContainsExcludedPage(String(describing: type(of: vc))) {
            
            print("🍎[TagWorks v\(CommonUtil.getSDKVersion()!)] \(event): \(type(of: vc)) [\(UIViewController.viewControllerPathDescription())]")
//            print("🍎[TagWorks v\(CommonUtil.getSDKVersion()!)] ")
            
            if event == "viewDidAppear" {
                let className = String(describing: type(of: vc))
                
                let dataBundle = DataBundle()
                dataBundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.PAGE_VIEW)
                dataBundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, className)
                dataBundle.putString(DataBundle.EVENT_TAG_PARAM_PAGE_PATH, "/\(UIViewController.viewControllerPathDescription())")
                let _ = TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_PAGE, bundle: dataBundle)
            }
        }
    }
    
    func applicationSwizzle(_ application: UIApplicationDelegate, _ event: String) {
        if TagWorks.sharedInstance.autoTrackingApplication {
            print("🍎[TagWorks v\(CommonUtil.getSDKVersion()!)] \(event): \(type(of: application))")
            
            var titleValue: String?
            
            if event == "didBecomeActive" {
                titleValue = "앱 포어그라운드"
            } else if event == "didEnterBackground" {
                titleValue = "앱 백그라운드"
            } else if event == "willTerminate" {
                titleValue = "앱 종료"
                
                // 안드로이드에서는 앱 종료 시점을 포착할 수 없기에 일시적으로 종료 로그를 보내지 않음
//                dataBundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, titleValue ?? "")
//                let _ = TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_USER_EVENT, bundle: dataBundle)
                
                // 큐에 남은 모든 로그들을 서버에 전송
                _ = TagWorks.sharedInstance.dispatch()
                return
            }
            
            let dataBundle = DataBundle()
            dataBundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.APP_STATUS)
            dataBundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, titleValue ?? "")
            let _ = TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_USER_EVENT, bundle: dataBundle)
        }
    }
    
    @available(iOS 13.0, *)
    func sceneSwizzle(_ scene: UISceneDelegate, _ event: String) {
        if TagWorks.sharedInstance.autoTrackingScene {
            print("🍎[TagWorks v\(CommonUtil.getSDKVersion()!)] \(event): \(type(of: scene))")
            
            var titleValue: String?
            
            let dataBundle = DataBundle()
            dataBundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.APP_STATUS)
            
            if event == "didBecomeActive" {
                titleValue = "앱 포어그라운드"
            } else if event == "didEnterBackground" {
                titleValue = "앱 백그라운드"
            } else if event == "didDisconnect" {
                titleValue = "앱 종료"
                
                // 안드로이드에서는 앱 종료 시점을 포착할 수 없기에 일시적으로 종료 로그를 보내지 않음
//                dataBundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, titleValue ?? "")
//                let _ = TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_USER_EVENT, bundle: dataBundle)
                
                // 큐에 남은 모든 로그들을 서버에 전송
                _ = TagWorks.sharedInstance.dispatch()
                return
            }
            
            dataBundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, titleValue ?? "")
            let _ = TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_USER_EVENT, bundle: dataBundle)
        }
    }
    
    // UIButton 클릭 스위즐링 시 실행 코드
    func buttonClickSwizzle(_ button: UIButton, event: UIEvent?) {
        let title = button.title(for: .normal) ?? "(no title)"
        print("🔍 버튼 클릭 감지: title: \(title)")
//        print("👆 버튼 클릭: \(button)")
        
        let dataBundle = DataBundle()
        dataBundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.CLICK)
        dataBundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, title)
        let _ = TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_USER_EVENT, bundle: dataBundle)
    }
}

// MARK: Swizzling Helper
/// 스위즐링을 하기위한 Helper 함수
extension SwizzlingManager {
    
    // 파라미터가 없는 메서드 swizzling
    func injectSwizzling(in cls: AnyClass,
                         selector: Selector,
                         callback: @escaping (AnyObject, Selector) -> Void) {
        // 인스턴스 메소드를 가져옴
        guard let method = class_getInstanceMethod(cls, selector) else { return }
        // 원래 구현 (또는 이전에 누가 스위즐링한 구현 - 함수 포인터를 가져옴)
        let originalIMP = method_getImplementation(method)
        
        let block: @convention(block) (AnyObject) -> Void = { target in
            callback(target, selector)
            
            typealias OriginalFunc = @convention(c) (AnyObject, Selector) -> Void
            let original = unsafeBitCast(originalIMP, to: OriginalFunc.self)
            original(target, selector)
        }
        
        let newIMP = imp_implementationWithBlock(block)
        method_setImplementation(method, newIMP)
    }
    
    // Bool 타입을 다루는 injectSwizzlingForBool 함수
    // 라이프 사이클 중 파라미터가 Bool 하나인 경우, (viewWillAppear(), viewDidAppear(), viewWillDisappear(), viewDidDisappear())
    func injectSwizzlingForBool(in cls: AnyClass,
                                selector: Selector,
                                callback: @escaping (AnyObject, Selector, Bool) -> Void) {
        guard let method = class_getInstanceMethod(cls, selector) else { return }
        let originalIMP = method_getImplementation(method)
        
        let key = "\(cls)-\(selector)"
        originalIMPs[key] = originalIMP

        let block: @convention(block) (AnyObject, Bool) -> Void = { target, arg in
            // 내 SDK 로직
            callback(target, selector, arg)

            // 원래 구현 호출
            typealias OriginalFunc = @convention(c) (AnyObject, Selector, Bool) -> Void
            let original = unsafeBitCast(originalIMP, to: OriginalFunc.self)
            original(target, selector, arg)
        }

        let newIMP = imp_implementationWithBlock(block)
        method_setImplementation(method, newIMP)
    }
    
    // 파라미터가 한개인 메소드를 AnyObject로 받아서 처리하는 함수 (Value Type이 아닌 경우)
    func injectOneParamSwizzling<T>(in cls: AnyClass,
                                    selector: Selector,
                                    argType: T.Type,
                                    callback: @escaping (AnyObject, Selector, T) -> Void) {
        guard let method = class_getInstanceMethod(cls, selector) else { return }
        let originalIMP = method_getImplementation(method)

        let block: @convention(block) (AnyObject, AnyObject) -> Void = { target, arg in
            guard let typedArg = arg as? T else {
                print("Type casting to T failed")
                return
            }

            // 내 SDK 동작
            callback(target, selector, typedArg)

            // 원래 동작
            typealias OriginalFunc = @convention(c) (AnyObject, Selector, AnyObject) -> Void
            let original = unsafeBitCast(originalIMP, to: OriginalFunc.self)
            original(target, selector, arg)
        }

        let newIMP = imp_implementationWithBlock(block)
        method_setImplementation(method, newIMP)
    }
    
    // 파라미터가 두개인 메서드를 Swizzling
    func injectTwoParamSwizzling<T1, T2> (
        in cls: AnyClass,
        selector: Selector,
        argType: (T1.Type, T2.Type),
        callback: @escaping (AnyObject, Selector, T1, T2) -> Void)
    {
        guard let method = class_getInstanceMethod(cls, selector) else { return }

        let originalIMP = method_getImplementation(method)

        let block: @convention(block) (AnyObject, AnyObject, AnyObject) -> Void = { target, arg1, arg2 in
            guard let typedArg1 = arg1 as? T1, let typedArg2 = arg2 as? T2 else {
                print("Type casting to T1 or T2 failed")
                return
            }

            callback(target, selector, typedArg1, typedArg2)

            typealias OriginalFunc = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void
            let original = unsafeBitCast(originalIMP, to: OriginalFunc.self)
            original(target, selector, arg1, arg2)
        }

        let newIMP = imp_implementationWithBlock(block)
        method_setImplementation(method, newIMP)
    }
    
    // 파라미터가 세개인 메서드를 Swizzling
    func injectThreeParamSwizzling<T1, T2, T3>(in cls: AnyClass,
                                               selector: Selector,
                                               argType: (T1.Type, T2.Type, T3.Type),
                                               callback: @escaping (AnyObject, Selector, T1, T2, T3) -> Void) {
        guard let method = class_getInstanceMethod(cls, selector) else { return }

        let originalIMP = method_getImplementation(method)

        let block: @convention(block) (AnyObject, AnyObject, AnyObject, AnyObject) -> Void = { target, arg1, arg2, arg3 in
            guard let typedArg1 = arg1 as? T1, let typedArg2 = arg2 as? T2 , let typedArg3 = arg3 as? T3 else {
                print("Type casting to T1 or T2 or T3 failed")
                return
            }

            callback(target, selector, typedArg1, typedArg2, typedArg3)

            typealias OriginalFunc = @convention(c) (AnyObject, Selector, AnyObject, AnyObject, AnyObject) -> Void
            let original = unsafeBitCast(originalIMP, to: OriginalFunc.self)
            original(target, selector, arg1, arg2, arg3)
        }

        let newIMP = imp_implementationWithBlock(block)
        method_setImplementation(method, newIMP)
    }
    
    // 파라미터가 두개인 메서드를 Swizzling - 리턴 타입이 Any? 타입인 경우.
    func injectTwoParamSwizzling<T1, T2, R> (
        in cls: AnyClass,
        selector: Selector,
        argType: (T1.Type, T2.Type),
        returnType: R.Type,
        callback: @escaping (AnyObject, Selector, T1, T2) -> Void)
    {
        guard let method = class_getInstanceMethod(cls, selector) else {
            print("🕵️[TagWorks Method Check] Method not found for selector: \(selector)")
            return
        }

        let originalIMP = method_getImplementation(method)

        let block: @convention(block) (AnyObject, AnyObject, AnyObject) -> Any? = { target, arg1, arg2 in
            guard let typedArg1 = arg1 as? T1, let typedArg2 = arg2 as? T2 else {
                print("Type casting to T1 or T2 failed")
                // NOTE: R이 기본 타입이면 적절한 기본값 반환 필요
                if returnType != Void.self {
                    if returnType == Bool.self {
                        // NOTE: R이 기본 타입이면 적절한 기본값 반환 필요
                        return unsafeBitCast(0, to: R.self)
                    }
                    return nil
                }
                return
            }

            callback(target, selector, typedArg1, typedArg2)

            typealias OriginalFunc = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Any?
            let original = unsafeBitCast(originalIMP, to: OriginalFunc.self)
            return original(target, selector, arg1, arg2)
        }

        let newIMP = imp_implementationWithBlock(block)
        method_setImplementation(method, newIMP)
    }
    
    // 파라미터가 세개인 메서드를 Swizzling - 리턴 타입이 Any? 타입인 경우.
    func injectThreeParamSwizzling<T1, T2, T3, R> (
        in cls: AnyClass,
        selector: Selector,
        argType: (T1.Type, T2.Type, T3.Type),
        returnType: R.Type,
        callback: @escaping (AnyObject, Selector, T1, T2, T3) -> Void)
    {
        guard let method = class_getInstanceMethod(cls, selector) else {
            print("Method not found for selector: \(selector)")
            return
        }

        let originalIMP = method_getImplementation(method)

        let block: @convention(block) (AnyObject, AnyObject, AnyObject, AnyObject) -> Any? = { target, arg1, arg2, arg3 in
            guard let typedArg1 = arg1 as? T1, let typedArg2 = arg2 as? T2 , let typedArg3 = arg3 as? T3 else {
                print("Type casting to T1 or T2 failed")
                // NOTE: R이 기본 타입이면 적절한 기본값 반환 필요
                if returnType != Void.self {
                    if returnType == Bool.self {
                        // NOTE: R이 기본 타입이면 적절한 기본값 반환 필요
                        return unsafeBitCast(0, to: R.self)
                    }
                    return nil
                }
                return
            }

            callback(target, selector, typedArg1, typedArg2, typedArg3)

            typealias OriginalFunc = @convention(c) (AnyObject, Selector, AnyObject, AnyObject, AnyObject) -> Any?
            let original = unsafeBitCast(originalIMP, to: OriginalFunc.self)
            return original(target, selector, arg1, arg2, arg3)
        }

        let newIMP = imp_implementationWithBlock(block)
        method_setImplementation(method, newIMP)
    }
    
    ///
    /// 스위즐링 함수를 기존 함수로 되돌리는 함수
    ///
    func restoreSwizzling(for cls: AnyClass, selector: Selector) {
        let key = "\(cls)-\(selector)"
        guard let method = class_getInstanceMethod(cls, selector),
              let originalIMP = originalIMPs[key] else {
            print("No original IMP stored for \(key)")
            return
        }

        method_setImplementation(method, originalIMP)
        originalIMPs.removeValue(forKey: key)
    }
}
