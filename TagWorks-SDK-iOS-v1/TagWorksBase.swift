//
//  TagWorksBase.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/16/24.
//

import Foundation
import WebKit

/// TagWorks에서 사용하는 UserDefault 관리 클래스입니다.
internal struct TagWorksBase {
    
    /// UserDefault 객체입니다.
    private let userDefaults: UserDefaults
    
    private let keychainStorage = KeychainStorage.sharedInstance
    private var isEnableKeychain = true
    
    /// UserDefault 인스턴스 초기화시 지정하는 식별자입니다.
    /// - Parameter suitName: UserDefault 식별자
    init(suitName: String?){
        self.userDefaults = UserDefaults(suiteName: suitName)!
        
        // 키체인에 저장할 용도로 사용
        let result = keychainStorage.migrate()
        if result == false {
            if #available(iOS 11.3, *) {
                print(SecCopyErrorMessageString(keychainStorage.lastErrorStatus, nil)!)
            }
        }
    }
    
    /// 유저 식별자 (고객 식별자)를 저장 및 반환합니다.
    public var userId: String? {
        get {
            return userDefaults.string(forKey: UserDefaultKey.userId)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKey.userId)
            userDefaults.synchronize()
        }
    }
    
    /// 방문자 식별자를 저장 및 반환합니다.
    /// 앱을 삭제해도 변하지 않도록 키체인을 이용하여 저장 및 반환하도록 변경 - by Kevin 2024.07.16
    public var visitorId: String? {
        get {
//            return userDefaults.string(forKey: UserDefaultKey.visitorId)
            return keychainStorage.findOrCreate()
        }
        set {
//            userDefaults.setValue(newValue, forKey: UserDefaultKey.visitorId)
//            userDefaults.synchronize()
            _ = keychainStorage.renew()
        }
    }
    
    /// 수집 허용 여부를 저장 및 반환합니다.
    public var optOut: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKey.optOut)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKey.optOut)
            userDefaults.synchronize()
        }
    }
    
    
    
    
//    func prepareWebConfiguration(completion: @escaping (WKWebViewConfiguration?) -> Void) {
//        let urlString = "www.obzen.com"
//        guard let url = URL(string: urlString) else { return }
//        
//        if #available(iOS 11.0, *) {
//            let uidCookie = HTTPCookie(properties: [
//                .domain: "쿠키대상 domain(xxx.com)",
//                .path: "/",
//                .name: "uid",
//                .value: "<사용자 식별자>",
//                .secure: "TRUE",
//                .expires: NSDate(timeIntervalSinceNow: 31556926) // 파라미터 값은 second
//            ])!
//            let ozvidCookie = HTTPCookie(properties: [
//                .domain: "쿠키대상 domain(xxx.com)",
//                .path: "/",
//                .name: "ozvid",
//                .value: TagWorks.instance.visitorId,
//                .secure: "TRUE",
//                .expires: NSDate(timeIntervalSinceNow: 31556926) // 파라미터 값은 second
//            ])!
//            let config = WKWebViewConfiguration()
//            var wkPool = WKProcessPool()
//            config.processPool = wkPool
//            var webView = WKWebView(frame: .zero, configuration: config)
//            webView.configuration.websiteDataStore.httpCookieStore.setCookie(uidCookie)
//            webView.configuration.websiteDataStore.httpCookieStore.setCookie(ozvidCookie)
//            
//            let request = URLRequest(url: url)
//            webView.load(request)
//            
//        } else {
//            // frameRect는 맞춰서 작성
//            var webView = WKWebView(frame: .zero)
//            var request: NSMutableURLRequest = NSMutableURLRequest(url: url)
//            var valueString = "uid='사용자 식별자';ozvid=\(TagWorks.instance.visitorId)"
//            request.addValue(valueString, forHTTPHeaderField: "Cookie")
//            webView.load(request as URLRequest)
//        }
//    }
}

//@available(iOS 11.0, *)
//extension WKWebViewConfiguration {
//    static func includeCookie(cookies: [HTTPCookie], completion: @escaping (WKWebViewConfiguration?) -> Void) {
//        let config = WKWebViewConfiguration()
//        let dataStore = WKWebsiteDataStore.nonPersistent()
//
//        DispatchQueue.main.async {
//            let waitGroup = DispatchGroup()
//
//            for cookie in cookies {
//                waitGroup.enter()
//                dataStore.httpCookieStore.setCookie(cookie) {
//                    waitGroup.leave()
//                }
//            }
//
//            waitGroup.notify(queue: DispatchQueue.main) {
//                config.websiteDataStore = dataStore
//                completion(config)
//            }
//        }
//    }
//}
