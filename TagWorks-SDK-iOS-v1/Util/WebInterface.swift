//
//  WebInterface.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by Digital on 7/24/24.
//

import Foundation
import WebKit

@objc final public class WebInterface: NSObject, WKScriptMessageHandler {
    
    let messageHandlerName = "TagWorksJSInterfaces"
    
    private var tagWorks: TagWorks?
    
    private override init() {
        super.init()
    }
    
    public convenience init(tagWorks: TagWorks) {
        self.init()
        
        self.tagWorks = tagWorks
    }
    
    /// WKWebView의 WKWebViewConfiguration에서 사용할 WKUserContentController 객체를 전달
    /// - WKUserContentController 내에 인터페이스 이름과 메세지를 받을 target을 지정한 뒤 해당 객체를 리턴
    func getContentController() -> WKUserContentController {
        let contentController = WKUserContentController()
        contentController.add(self, name: messageHandlerName)
        return contentController
    }
    
    /// WKScriptMessgeHandler Protocol
    /// 실제로 WebView Javascript에서 호출한 메세지 핸들러를 처리하는 부분
    /// 웹뷰에서만 쓰는 고유 Key 값 : tag_id (서버에서는 바이패스)
 
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == messageHandlerName {
            // parameter 파싱 후 event 생성
            if let dics: [String: Any] = message.body as? Dictionary {
                var tagId: String?
                var userId: String?
                var url: String?
                var urlRef: String?
                var eventType: String?
                var pageTitle: String?
                var searchKeyword: String?
                var customUserPath: String?
//                var dimensions: [Dictionary<String, String>]?
                var dimensions: String?
                
                
                if dics.index(forKey: "tagId") != nil {
                    tagId = dics["tagId"] as? String
                }
                if dics.index(forKey: "userId") != nil {
                    userId = dics["userId"] as? String
                }
                
                if dics.index(forKey: "dimensions") != nil {
//                    dimensions = dics["dim"] as? [Dictionary<String, String>]
                    dimensions = dics["dimensions"] as? String
                    // String을 파싱하여 key, value형태로 만들고 Dimension 클래스에 타입을 하나 더 추가하여, string을 만들지 않고 그냥 전송토록 함.(delemeter: &)
                }

            }
//            if let dics: [String: Any] = message.body as? Dictionary, let action = dics["action"] as? String {
//                
//                let webAction = WebAction(rawValue: action)
//                switch webAction {
//                case .changeStatusBarColor:
//                    if let color = dics["bgColor"] as? String, let isDarkIcon = dics["isDarkIcon"] as? Bool {
//                        self.statusBarView?.backgroundColor = UIColor(hexString: color)
//                        if isDarkIcon == true {
//                            statusBarStyle = .default
//                        } else {
//                            statusBarStyle = .lightContent
//                        }
//                        setNeedsStatusBarAppearanceUpdate()
//                    }
//                case .goBack:
//                    self.popVC()
//                default:
//                    print("Undefined action: \(String(describing: webAction))")
//                }
//            }
        }
    }
    

    
    
    /// # WebView에서 설정하는 방법
    /// let config = WKWebViewConfiguration()
    /// config.userContentController = TagWorks.webInterface.getContentController()
    /// webView = WKWebView(frame: view.bounds, configuration: config)
    
    
    /// # JavaScript 에서 호출하는 방법
    /// window.webkit.messageHandlers.TagWorksJSInterfaces.postMessage("params")
    ///
    /// window.webkit.messageHandlers.TagWorksJSInterfaces.postMessage([
    ///    key1: 'value1',
    ///    key2: 'value2'
    /// ])
}

