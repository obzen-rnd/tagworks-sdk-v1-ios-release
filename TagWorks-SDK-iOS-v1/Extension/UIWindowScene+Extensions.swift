//
//  UIWindowScene+Extensions.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 6/9/25.
//

import Foundation
import UIKit
import ObjectiveC.runtime

@available(iOS 13.0, *)
extension UIWindowScene {
    
    static var activeScenes = 0
    
    public static func swizzleAllSceneDelegates() {
        swizzleAllSceneDelegatesLifecycle()
    }
    
    //
    // 모든 SceneDelegate 스위즐링
    //
    private static func swizzleAllSceneDelegatesLifecycle() {
        
        // 스위즐링 하고자 하는 메서드만 옵션처리
        let swizzleFlag: [String: Bool] = ["willConnectTo": false,
                                           "didBecomeActive": true,
                                           "willResignActive": false,
                                           "willEnterForeground": false,
                                           "didEnterBackground": true,
                                           "didDisconnect": true,
                                           
                                           "openURLContexts": false,
                                           "universalLink": false]
        
        UIApplication.shared.connectedScenes.forEach { scene in
            guard let delegate = scene.delegate,
                  let cls = object_getClass(delegate) else { return }

            // scene(_:willConnectTo:options:)
            if swizzleFlag["willConnectTo"]! {
                
                SwizzlingManager.sharedInstance.injectThreeParamSwizzling(
                    in: cls,
                    selector: #selector(UIWindowSceneDelegate.scene(_:willConnectTo:options:)),
                    argType: (UIScene.self, UISceneSession.self, UIScene.ConnectionOptions.self)) { target, sel, scene, sceneSession, options in
                        print("🆕 SceneDelegate.willConnectTo")
                }
            }

            // sceneDidDisconnect
            if swizzleFlag["didDisconnect"]! {
                
                activeScenes -= 1
                
                SwizzlingManager.sharedInstance.injectOneParamSwizzling (
                    in: cls,
                    selector: #selector(UIWindowSceneDelegate.sceneDidDisconnect(_:)),
                    argType: UIScene.self) { target, sel, scene in
                        if activeScenes == 0 {
                            // 활성화 된 Scene이 모두 닫힘으로 앱이 종료되는 것이라 판단
//                          print("❌ SceneDelegate.didDisconnect")
                            SwizzlingManager.sharedInstance.sceneSwizzle(target as! UISceneDelegate, "didDisconnect")
                        }
                    }
                
            }

            // sceneDidBecomeActive
            if swizzleFlag["didBecomeActive"]! {
                
                activeScenes += 1
                
                SwizzlingManager.sharedInstance.injectOneParamSwizzling(
                    in: cls,
                    selector: #selector(UIWindowSceneDelegate.sceneDidBecomeActive(_:)),
                    argType: UIScene.self) { target, sel, scene in
//                        print("▶️ SceneDelegate.didBecomeActive")
                        SwizzlingManager.sharedInstance.sceneSwizzle(target as! UISceneDelegate, "didBecomeActive")
                }
            }

            // sceneWillResignActive
            if swizzleFlag["willResignActive"]! {
                
                SwizzlingManager.sharedInstance.injectOneParamSwizzling(
                    in: cls,
                    selector: #selector(UIWindowSceneDelegate.sceneWillResignActive(_:)),
                    argType: UIScene.self) { target, sel, scene in
                        print("🏝️ SceneDelegate.willResignActive")
                }
            }

            // sceneWillEnterForeground
            if swizzleFlag["willEnterForeground"]! {
                
                SwizzlingManager.sharedInstance.injectOneParamSwizzling(
                    in: cls,
                    selector: #selector(UIWindowSceneDelegate.sceneWillEnterForeground(_:)),
                    argType: UIScene.self) { target, sel, scene in
                        print("🌄 SceneDelegate.willEnterForeground")
                }
            }

            // sceneDidEnterBackground
            if swizzleFlag["didEnterBackground"]! {
                
                SwizzlingManager.sharedInstance.injectOneParamSwizzling(
                    in: cls,
                    selector: #selector(UIWindowSceneDelegate.sceneDidEnterBackground(_:)),
                    argType: UIScene.self) { target, sel, scene in
//                        print("🌙 SceneDelegate.didEnterBackground")
                        SwizzlingManager.sharedInstance.sceneSwizzle(target as! UISceneDelegate, "didEnterBackground")
                        
                        // 백그라운드 진입 시 해야할 기능 정의
//                        let manager = BackgroundTaskManager()
//                        manager.performBackgroundFetch()
                }
            }
            
            // scene open url
            if swizzleFlag["openURLContexts"]! {
                
                SwizzlingManager.sharedInstance.injectTwoParamSwizzling(
                    in: cls,
                    selector: #selector(UIWindowSceneDelegate.scene(_:openURLContexts:)),
                    argType: (UIScene.self, Set<UIOpenURLContext>.self)) { target, sel, scene, urlContexts in
                    
                    urlContexts.forEach { ctx in
                        print("🔓 SceneDelegate URL opened: \(ctx.url.absoluteString)")
                    }
                }
            }
            
            // Scene restoration / User Activity
            if swizzleFlag["universalLink"]! {
                
                SwizzlingManager.sharedInstance.injectTwoParamSwizzling(
                    in: cls,
                    selector: #selector(UIWindowSceneDelegate.scene(_:continue:)),
                    argType: (UIScene.self, NSUserActivity.self)) { target, sel, scene, activity in
                        print("📱 Scene continued via Universal Link: \(activity.webpageURL?.absoluteString ?? "")")
                }
            }
        }
    }
}
