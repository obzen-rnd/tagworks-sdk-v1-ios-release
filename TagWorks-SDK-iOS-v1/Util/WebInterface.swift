//
//  WebInterface.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by Digital on 7/24/24.
//

import UIKit
import WebKit

protocol WebInterfaceDelegate: AnyObject {
    func isEqualSiteId(idsite: String) -> Bool
    func addWebViewEvent(event: Event)
}

@objc final public class WebInterface: NSObject, WKScriptMessageHandler {
    
    @objc public let messageHandlerName = "TagWorksJSInterfaces"
    @objc public let omCmsPopupHandlerName = "TagWorksOnCmsPopup"
    
    weak var delegate: WebInterfaceDelegate?
    
    public override init() {
        super.init()
    }
    
    /// WKWebView의 WKWebViewConfiguration에서 사용할 WKUserContentController 객체를 전달
    /// - WKUserContentController 내에 인터페이스 이름과 메세지를 받을 target을 지정한 뒤 해당 객체를 리턴
    @objc public func getContentController() -> WKUserContentController {
        let contentController = WKUserContentController()
        contentController.add(self, name: messageHandlerName)
        return contentController
    }
    
    /// WKWebView의 WKWebViewConfiguration에서 사용할 WKUserContentController 객체를 전달받아 Script Interface 연결
    @objc public func addTagworksWebInterface(_ contentController: WKUserContentController) {
        contentController.add(self, name: messageHandlerName)
        contentController.add(self, name: omCmsPopupHandlerName)
    }
    
    
    // MARK: WKScriptMessgeHandler Protocol
    /// 실제로 WebView Javascript에서 호출한 메세지 핸들러를 처리하는 부분
    /// 웹뷰에서만 쓰는 고유 Key 값 : tag_id (서버에서는 바이패스)
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] WebInterface: \(message.name): \(message.body)")
        
        if (!TagWorks.sharedInstance.isInitialize()) {
            return
        }
        
        if message.name == messageHandlerName {
            // WebInterface 로그 출력
            // UI에서 출력하기 위한 용도
            NotificationCenter.default.post(name:NSNotification.Name("TagWorks-WebInterface"), object:message.body, userInfo:nil)
            
            // parameter 파싱 후 event 생성
            if let dics: [String: Any] = message.body as? Dictionary {
//                dics["url"] = "http://192.168.20.53:8070/jrecommend/oncms/T_RA1254312_shop.html?a=1&bn=2"
                webInterfaceDidReceiveDictionary(dics)
            }
        } else if message.name == omCmsPopupHandlerName {
            // OnCMSPopup 출력 용도
            // UI에서 출력하기 위한 용도
            NotificationCenter.default.post(name:NSNotification.Name("TagWorks-WebInterface"), object:message.body, userInfo:nil)
            
            // parameter 파싱 후 event 생성
            if let dics: [String: Any] = message.body as? Dictionary {
                webInterfaceDidReceiveOnCmsPopupDictionary(dics)
            }
        }
    }
    
    // 웹뷰에서 태깅 로그 발생 시 SDK에서 수신 처리
    @objc public func webInterfaceDidReceiveDictionary(_ msgDictionary: Dictionary<String, Any>) {
        
        var idSite: String?
        var eventCategory: String?
        var url: String?
        var urlRef: String?
        
        if msgDictionary.index(forKey: "idsite") != nil {
            idSite = msgDictionary["idsite"] as? String
        }
        if msgDictionary.index(forKey: "e_c") != nil {
            eventCategory = msgDictionary["e_c"] as? String
            // 웹뷰의 visitorId를 App의 visitorId로 교체
            eventCategory = eventCategory?.replacingOccurrences(of: "{{vstor_id}}", with: (delegate as! TagWorks).visitorId)
        }
        if msgDictionary.index(forKey: "url") != nil {
            url = msgDictionary["url"] as? String
        }
        if msgDictionary.index(forKey: "urlref") != nil {
            urlRef = msgDictionary["urlref"] as? String
        }
        
        if let delegate = self.delegate {
            // App siteid와 웹뷰의 siteid를 비교하여, 다를 경우 로그만 출력..
            if let idSite {
                if !delegate.isEqualSiteId(idsite: idSite) {
                    DefaultLogger(minLevel: .warning).info("WebView siteid : \(idSite)")
                }
            }
            
            // 앱 웹뷰와 웹브라우저 구분을 하기 위해 idsite 값은 app의 idsite 값으로 대체
            let appSiteId = TagWorks.sharedInstance.siteId
            
            if let url = url, let urlref = urlRef {
                let webViewEvent = Event(tagWorks: delegate as! TagWorks, url: URL(string: url), urlReferer: URL(string: urlref), eventType: "", eventCategory: eventCategory, siteId: appSiteId)
                delegate.addWebViewEvent(event: webViewEvent)
            } else if let url = url {
                let webViewEvent = Event(tagWorks: delegate as! TagWorks, url: URL(string: url), eventType: "", eventCategory: eventCategory, siteId: appSiteId)
                delegate.addWebViewEvent(event: webViewEvent)
            } else {
                let webViewEvent = Event(tagWorks: delegate as! TagWorks, eventType: "", eventCategory: eventCategory, siteId: appSiteId)
                delegate.addWebViewEvent(event: webViewEvent)
            }
        }
    }
    
    // 웹뷰에서 SDK를 통해 OnCMS 팝업을 출력 및 닫도록 시키는 용도
    @objc public func webInterfaceDidReceiveOnCmsPopupDictionary(_ msgDictionary: Dictionary<String, Any>) {
        var onCmsUrl: String?
        var custId: String?
        var rcmdAreaCd: String?
        var command: String?
        
        if msgDictionary.index(forKey: "onCmsUrl") != nil {
            onCmsUrl = msgDictionary["onCmsUrl"] as? String
        }
        if msgDictionary.index(forKey: "cust_id") != nil {
            custId = msgDictionary["cust_id"] as? String
        }
        if msgDictionary.index(forKey: "rcmd_area_cd") != nil {
            rcmdAreaCd = msgDictionary["rcmd_area_cd"] as? String
        }
        if msgDictionary.index(forKey: "command") != nil {
            command = msgDictionary["command"] as? String
        }
        
        var rootVC: UIViewController? {
            if #available(iOS 13.0, *) {
                return UIApplication.shared
                    .connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?.rootViewController
            } else {
                return UIApplication.shared.keyWindow?.rootViewController
            }
        }
        
        if command != nil {
            if command == "close" {
                TagWorksPopup.sharedInstance.webPopupViewControllerDismiss()
            }
        } else {
            TagWorksPopup.sharedInstance.onCMSPopup(onCmsUrl: onCmsUrl ?? "", cust_id: custId ?? "", rcmd_area_cd: rcmdAreaCd ?? "", owner: rootVC!)
        }
    }
}

    
    
    /// # WebView에서 설정하는 방법
//    / let config = WKWebViewConfiguration()
//    / config.userContentController = TagWorks.webInterface.getContentController()
//    / webView = WKWebView(frame: view.bounds, configuration: config)
    
    
    /// # JavaScript 에서 호출하는 방법
    /// window.webkit.messageHandlers.TagWorksJSInterfaces.postMessage("params")
    ///
    /// window.webkit.messageHandlers.TagWorksJSInterfaces.postMessage([
    ///    key1: 'value1',
    ///    key2: 'value2'
    /// ])
    

    // 웹브라우저 쿠키 설정 관련 코드
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
//                .secure: true,
//                .expires: NSDate(timeIntervalSinceNow: 31556926) // 파라미터 값은 second
//            ])!
//            let ozvidCookie = HTTPCookie(properties: [
//                .domain: "쿠키대상 domain(xxx.com)",
//                .path: "/",
//                .name: "ozvid",
//                .value: TagWorks.instance.visitorId,
//                .secure: true,
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
//}

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

