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

public class WebViewManager: NSObject, WKNavigationDelegate {

    private var webView: WKWebView?
    var webViewDelegate: WebViewManagerDelegate?
    
    public init(webView: WKWebView) {
        super.init()
        self.webView = webView
        self.webView?.navigationDelegate = self
    }
    
    // 커스텀 URL 처리
    private func handleCustomURL(_ url: URL) {
        // URL에서 정보를 추출하여 원하는 작업을 수행
        print("🔗 [TagWorks] Custom URL clicked: \(url.absoluteString)")

        // URL이 유효한지 체크
        guard UIApplication.shared.canOpenURL(url) else {
            print("⚠️ [TagWorks] 유효하지 않은 URL.")
            return
        }
        
        // URL이 앱에서 처리 가능한지 확인
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                if success {
                    print("✅ [TagWorks] Successfully opened \(url.absoluteString)")
                    self.webViewDelegate?.webPopupViewControllerDismiss()
                } else {
                    print("❌ [TagWorks] Failed to open \(url.absoluteString)")
                }
            })
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(url)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    // 웹 페이지 로딩이 완료되었을 때 호출되는 메서드
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🟢 [TagWorks] 웹 페이지 로딩 완료: \(webView.url?.absoluteString ?? "unknown")")
        webViewDelegate?.webViewDidFinishLoad(webView)
    }
    
    // 오류 발생 시 호출되는 메서드
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("🔴 [TagWorks] 웹 페이지 로딩 실패: \(error.localizedDescription)")
        webViewDelegate?.webViewDidFailLoad(webView, withError: error)
    }
    
    // 네비게이션 시작 시 호출되는 메서드 (선택 사항)
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🟡 [TagWorks] 웹 페이지 로딩 시작: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    // 웹 페이지 로딩 중 오류 처리 (선택 사항)
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("↪️ [TagWorks] 서버 리디렉션 발생")
    }
    
    // 웹뷰 내에서 URL 클릭을 감지하고 처리하는 델리게이트 메서드
    public func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        // 클릭 이벤트인지 확인
        if navigationAction.navigationType == .linkActivated {
            if url.scheme == "http" || url.scheme == "https" {
                print("🌐 [TagWorks] 외부 링크 클릭: \(url.absoluteString)")
                webViewDelegate?.showDetailWebViewContoller(url: url)
            } else {
                handleCustomURL(url)
                decisionHandler(.cancel)
                return
            }
        }
        
        // 다른 URL들은 기본 처리하도록 진행
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        // 다른 URL들은 기본 처리하도록 진행
        decisionHandler(.allow)
    }
}
