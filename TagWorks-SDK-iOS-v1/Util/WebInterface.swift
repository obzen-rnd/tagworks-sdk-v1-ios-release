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
    
    public let messageHandlerName = "TagWorksJSInterfaces"
    
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
    }
    
    /// WKScriptMessgeHandler Protocol
    /// 실제로 WebView Javascript에서 호출한 메세지 핸들러를 처리하는 부분
    /// 웹뷰에서만 쓰는 고유 Key 값 : tag_id (서버에서는 바이패스)
 
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        print(message.name)
        print("👨🏻‍💻[TagWorks] WebInterface: \(message.body)")
        if message.name == messageHandlerName {
            
            // UI에서 출력하기 위한 용도
            NotificationCenter.default.post(name:NSNotification.Name("TagWorks-WebInterface"), object:message.body, userInfo:nil)
            
            // parameter 파싱 후 event 생성
            if let dics: [String: Any] = message.body as? Dictionary {
                var idSite: String?
                var eventCategory: String?
                var url: String?
                var urlRef: String?
                
                if dics.index(forKey: "idsite") != nil {
                    idSite = dics["idsite"] as? String
                }
                if dics.index(forKey: "e_c") != nil {
                    eventCategory = dics["e_c"] as? String
                    // 웹뷰의 visitorId를 App의 visitorId로 교체
                    eventCategory = eventCategory?.replacingOccurrences(of: "{{vstor_id}}", with: (delegate as! TagWorks).visitorId)
                }
                if dics.index(forKey: "url") != nil {
                    url = dics["url"] as? String
                }
                if dics.index(forKey: "urlref") != nil {
                    urlRef = dics["urlref"] as? String
                }
                
                if let delegate = self.delegate {
//                    // App siteid와 웹뷰의 siteid를 비교하여, 다를 경우 로그만 출력..
//                    if !delegate.isEqualSiteId(idsite: siteid) {
//                        DefaultLogger(minLevel: .warning).info("WebView siteid is not equal App siteid!!")
//                    }
                    
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
}

