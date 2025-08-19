//
//  UIApplication+Extensions.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 5/21/25.
//

import Foundation
import UIKit
import ObjectiveC.runtime

final class Application {
    static var didApplicationSwizzle = false
    
    @objc public static func initializeApplicationTracking() {
        guard !didApplicationSwizzle else { return }
        didApplicationSwizzle = true
        
        UIApplication.swizzleAppDelegate()
        if #available(iOS 13.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIWindowScene.swizzleAllSceneDelegates()
            }
        }
    }
}

//
// AppDelegate 스위즐링
//
extension UIApplication {
    
    public static func swizzleAppDelegate() {
        
        swizzleAppDelegateLifecycle()
    }
    
    private static func swizzleAppDelegateLifecycle() {
        
        // 스위즐링 하고자 하는 메서드만 옵션처리
        let swizzleFlag: [String: Bool] = ["didFinishLaunchingWithOptions": false,
                                           "didBecomeActive": true,
                                           "didEnterBackground": true,
                                           "willEnterForeground": false,
                                           "willTerminate": true,
                                           
                                           "openURL": true,
                                           "deviceTokenRegistered": false,
                                           "deviceTokenRegistFailed": false,
                                           "universalLink": false,
                                           "pushNotification": false]
        
        guard let appDelegate = UIApplication.shared.delegate,
              let cls = object_getClass(appDelegate) else {
            print("[🚀 TagWorks] AppDelegate not found")
            return
        }
        
        
        // application(didFinishLaunchingWithOptions)
        if swizzleFlag["didFinishLaunchingWithOptions"]! {
            
            SwizzlingManager.sharedInstance.injectTwoParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)),
                argType: (UIApplication.self, [UIApplication.LaunchOptionsKey: Any]?.self)) { target, sel, app, options  in
//                    print("🚀 AppDelegate.didFinishLaunchingWithOptions")
            }
        }

        // applicationDidBecomeActive
        if swizzleFlag["didBecomeActive"]! {
            
            SwizzlingManager.sharedInstance.injectOneParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)),
                argType: UIApplication.self) { target, sel, app in
//                    print("🛺 AppDelegate.didBecomeActive")
                    SwizzlingManager.sharedInstance.applicationSwizzle(target as! UIApplicationDelegate, "didBecomeActive")
            }
        }

        // applicationDidEnterBackground
        if swizzleFlag["didEnterBackground"]! {
            
            SwizzlingManager.sharedInstance.injectOneParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)),
                argType: UIApplication.self) { target, sel, app in
//                    print("🌙 AppDelegate.didEnterBackground")
                    SwizzlingManager.sharedInstance.applicationSwizzle(target as! UIApplicationDelegate, "didEnterBackground")
            }
        }

        // applicationWillEnterForeground
        if swizzleFlag["willEnterForeground"]! {
            
            SwizzlingManager.sharedInstance.injectOneParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)),
                argType: UIApplication.self) { target, sel, app in
                    print("🌄 AppDelegate.willEnterForeground")
            }
        }

        // applicationWillTerminate
        if swizzleFlag["willTerminate"]! {
            SwizzlingManager.sharedInstance.injectOneParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)),
                argType: UIApplication.self) { target, sel, app in
//                    print("❌ AppDelegate.willTerminate")
                    SwizzlingManager.sharedInstance.applicationSwizzle(target as! UIApplicationDelegate, "willTerminate")
            }
        }
        
        // open Url - return Bool
        if swizzleFlag["openURL"]! {
            
            SwizzlingManager.sharedInstance.injectThreeParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.application(_:open:options:)),
                argType: (UIApplication.self, URL.self, [UIApplication.OpenURLOptionsKey: Any].self)) { target, sel, app, url, options in
                
                    print("🌐 AppDelegate Open URL: \(url)")
                    SwizzlingManager.sharedInstance.applicationSwizzle(target as! UIApplicationDelegate, "openURL", url)
            }
        }
        
        // Push
        // Register Device Token
        if swizzleFlag["deviceTokenRegistered"]! {
            
            SwizzlingManager.sharedInstance.injectTwoParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
                argType: (UIApplication.self, Data.self)) { target, sel, app, deviceToken in
                    let tokenString = deviceToken.map {String(format: "%02.2hhx", $0)}.joined()
//                    print("📲 Device token registered: \(tokenString)")
                    SwizzlingManager.sharedInstance.applicationSwizzle(target as! UIApplicationDelegate, "deviceTokenRegistered")
            }
        }

        // Fail to Register Device Token
        
        if swizzleFlag["deviceTokenRegistFailed"]! {
            
            SwizzlingManager.sharedInstance.injectTwoParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:)),
                argType: (UIApplication.self, Error.self)) { target, sel, app, error in
                
                    print("❗️ Push registration failed: \(error.localizedDescription)")
            }
        }
//
        // Universal Links
        if swizzleFlag["universalLink"]! {
            
            SwizzlingManager.sharedInstance.injectThreeParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.application(_:continue:restorationHandler:)),
                argType: (UIApplication.self, NSUserActivity.self, (([UIUserActivityRestoring]?) -> Void).self),
                returnType: Bool.self) { target, sel, app, userActivity, restorationHandler in
                    
                    print("🔗 Universal Link: \(userActivity.webpageURL?.absoluteString ?? "")")
                }
        }
        
        // Push (포그라운드)
        if swizzleFlag["pushNotification"]! {
            
            SwizzlingManager.sharedInstance.injectTwoParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:)),
                argType: (UIApplication.self, [AnyHashable : Any].self),
                returnType: Void.self) { target, sel, app, userInfo in
                    
                    print("📩 Push Notification: \(userInfo["aps"] ?? "")")
                }
        }
        
        // Push (백그라운드)
        if swizzleFlag["pushNotification"]! {
            
            SwizzlingManager.sharedInstance.injectThreeParamSwizzling(
                in: cls,
                selector: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)),
                argType: (UIApplication.self, [AnyHashable : Any].self, ((UIBackgroundFetchResult) -> Void).self),
                returnType: Void.self) { target, sel, app, userInfo, completionHandler in
                    
                    print("📩 Push Notification: \(userInfo["aps"] ?? "")")
                    
                    // 반드시 시스템이 알 수 있도록 호출해줘야 함!
                    completionHandler(.noData)
                }
        }

    }
        
    
//    private static func pushSwizzleMethod(in cls: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
//        guard let originalMethod = class_getInstanceMethod(cls, originalSelector),
//              let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else {
//            print("❗️ Swizzling failed: method not found")
//            return
//        }
//
//        let didAddMethod = class_addMethod(cls,
//                                           swizzledSelector,
//                                           method_getImplementation(swizzledMethod),
//                                           method_getTypeEncoding(swizzledMethod))
//
//        if didAddMethod {
//            if let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector) {
//                method_exchangeImplementations(originalMethod, swizzledMethod)
//            }
//        } else {
//            method_exchangeImplementations(originalMethod, swizzledMethod)
//        }
//    }
    
    
    
//    // Objective-C 방식으로 직접 Swizzling
//    static public func swizzleRemoteNotificationFetchMethod() {
//        guard let appDelegate = UIApplication.shared.delegate,
//              let cls = object_getClass(appDelegate) else { return }
//
//        let originalSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
//        let swizzledSelector = #selector(SwizzleApplication.swizzled_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
//
//        guard let originalMethod = class_getInstanceMethod(cls, originalSelector),
//              let swizzledMethod = class_getInstanceMethod(SwizzleApplication.self, swizzledSelector) else {
//            print("❗️ Swizzling failed: method not found")
//            return
//        }
//
//        let didAdd = class_addMethod(cls,
//                                     swizzledSelector,
//                                     method_getImplementation(swizzledMethod),
//                                     method_getTypeEncoding(swizzledMethod))
//
//        if didAdd {
//            if let swizzled = class_getInstanceMethod(cls, swizzledSelector) {
//                method_exchangeImplementations(originalMethod, swizzled)
//            }
//        } else {
//            method_exchangeImplementations(originalMethod, swizzledMethod)
//        }
//
//        print("✅ Swizzling succeeded for didReceiveRemoteNotification")
//    }
    
//    // Receive Push
//    @objc func swizzled_application(_ application: UIApplication,
//                                    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//                                    fetchCompletionHandler completion: @escaping (UIBackgroundFetchResult) -> Void) {
//        // 내 로직
//        print("📩 Push received: \(userInfo)")
//        
////        self.swizzled_application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completion)
//        
//        // 원래 구현 호출 (Swizzling으로 원래 메서드가 swizzled_application으로 옮겨짐)
//        let selector = #selector(swizzled_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
//        if let originalIMP = class_getMethodImplementation(type(of: self), selector) {
//            typealias OriginalFunc = @convention(c) (Any, Selector, UIApplication, [AnyHashable: Any], @escaping (UIBackgroundFetchResult) -> Void) -> Void
//            let function = unsafeBitCast(originalIMP, to: OriginalFunc.self)
//
//            // self가 application delegate 인스턴스여야 정확함
//            function(self, selector, application, userInfo, completion)
//        } else {
//            // fallback
//            completion(.noData)
//        }
//    }

}



