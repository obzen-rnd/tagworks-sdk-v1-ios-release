//
//  WebViewManager.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 2/25/25.
//

import Foundation
@preconcurrency import WebKit

protocol WebViewManagerDelegate: AnyObject {
    func webViewDidFinishLoad(_ webView: WKWebView)
    func webViewDidFailLoad(_ webView: WKWebView, withError error: Error)
    func webPopupViewControllerDismiss()
    func showDetailWebViewContoller(url: URL)
}

class WebViewManager: NSObject, WKNavigationDelegate {

    private var webView: WKWebView?
    public var webViewDelegate: WebViewManagerDelegate?
    
    init(webView: WKWebView) {
        super.init()
        self.webView = webView
        self.webView?.navigationDelegate = self
    }
    
    // 커스텀 URL 처리
    private func handleCustomURL(url: URL) {
        // URL에서 정보를 추출하여 원하는 작업을 수행
        print("Custom URL clicked: \(url.absoluteString)")

        // iOS 9 이상에서는 URL 스킴을 실행하기 전에 먼저 canOpenURL을 호출해야 합니다.
        if UIApplication.shared.canOpenURL(url) {
            // URL이 앱에서 처리 가능한지 확인
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    if success {
                        if let delegate = self.webViewDelegate {
                            delegate.webPopupViewControllerDismiss()
                        }
                        
                        print("Successfully opened obzenapp:// URL")
                    } else {
                        print("Failed to open obzenapp:// URL")
                    }
                })
            } else {
                // Fallback on earlier versions
            }
        } else {
            print("This URL scheme is not registered or cannot be opened")
        }
    }
    
    // 웹 페이지 로딩이 완료되었을 때 호출되는 메서드
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("웹 페이지 로딩 완료")
        // 여기서 로딩 완료 후 처리할 추가 로직을 작성합니다.
        if let webView = self.webView {
            if let delegate = self.webViewDelegate {
                delegate.webViewDidFinishLoad(webView)
            }
        }
    }
    
    // 오류 발생 시 호출되는 메서드
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("웹 페이지 로딩 실패: \(error.localizedDescription)")
        if let webView = self.webView {
            if let delegate = self.webViewDelegate {
                delegate.webViewDidFailLoad(webView, withError: error)
            }
        }
    }
    
    // 네비게이션 시작 시 호출되는 메서드 (선택 사항)
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("웹 페이지 로딩 시작")
    }
    
    // 웹 페이지 로딩 중 오류 처리 (선택 사항)
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("서버 리디렉션 발생")
    }
    
    // 웹뷰 내에서 URL 클릭을 감지하고 처리하는 델리게이트 메서드
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // 클릭 이벤트인지 확인 (linkActivated == 클릭)
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                if url.scheme == "http" || url.scheme == "https" {
                    if let delegate = self.webViewDelegate {
                        delegate.showDetailWebViewContoller(url: url)
                    }
                } else {
                    handleCustomURL(url: url)
                    decisionHandler(.cancel) // 웹뷰가 URL을 기본적으로 로드하지 않도록 막음
                    return
                }
                //            // 커스텀 URL 스킴 (obzenapp://)을 처리하는 조건
                //            if url.scheme == "obzenapp" {
                //                // 예시: obzenapp:// URL을 분석하고 앱 내에서 원하는 동작을 처리
                //                handleCustomURL(url: url)
                //                decisionHandler(.cancel) // 웹뷰가 URL을 기본적으로 로드하지 않도록 막음
                //                return
                //            }
            }
        }
        
        // 다른 URL들은 기본 처리하도록 진행
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        // 다른 URL들은 기본 처리하도록 진행
        decisionHandler(.allow)
    }
}
