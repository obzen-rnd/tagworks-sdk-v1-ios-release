//
//  DetailWebViewController.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 3/20/25.
//

import Foundation
import UIKit
@preconcurrency
import WebKit

class DetailWebViewController: UIViewController {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webViewContainerView: UIView!
    public var requestUrl: String?
    public var isModal: Bool = false
    var mainWebView: WKWebView? {
        didSet {
            mainWebView?.navigationDelegate = self
//            mainWebView?.uiDelegate = self
        }
    }
    
//    convenience public init(loadUrl: String, isModal: Bool = false) {
//        self.init()
//        
//        requestUrl = loadUrl
//        self.isModal = isModal
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        setNavigationBarColor(.black)
        
        navigationItem.title = "자세히 보기"
        
        self.view.backgroundColor = .black
        self.webViewContainerView.backgroundColor = .black

        /// 코드로 웹뷰를 만들어 사용하는 방법
        self.mainWebView = createWebView()
//        self.mainWebView?.fillSuperview()
        
        // 웹뷰 모든 데이터(캐시) 삭제
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: {
            (records) -> Void in
            for record in records {
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                // remove callback
            }
        })
    }
    
    func setNavigationBarColor(_ color: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navigationItem.scrollEdgeAppearance = appearance
            navigationItem.scrollEdgeAppearance?.backgroundColor = color   // 스크롤 되기 전 네비게이션바 색상
            navigationItem.standardAppearance = appearance
            navigationItem.standardAppearance?.backgroundColor = color     // 위로 스크롤 시 네비게이션바 색상
        } else {
            guard let navigationBar = navigationController?.navigationBar else { return }

            // 배경색을 적용한 이미지 생성
            let backgroundImage = UIImage(color: color)
            
            navigationBar.setBackgroundImage(backgroundImage, for: .default)
            navigationBar.shadowImage = UIImage() // 네비게이션 바 하단 그림자 제거
            navigationBar.isTranslucent = false // 불투명 설정
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadURL(requestUrl ?? "")
    }
    
    func createWebView() -> WKWebView {
        
        let scriptContent = """
            var meta = document.createElement('meta');
                       meta.setAttribute('name', 'viewport');
                       meta.setAttribute('content', 'width=device-width, minimum-scale=0.5, maximum-scale=1.0, user-scalable=no');
                       document.getElementsByTagName('head')[0].appendChild(meta);
            """
        let userScript = WKUserScript(source: scriptContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
//        // Swift에 JavaScript 인터페이스 연결
        let contentController = TagWorks.sharedInstance.webViewInterface.getContentController()
        contentController.addUserScript(userScript)
        

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
//        // Zoom disable
//        webView.scrollView.delegate = self
//        webView.scrollView.maximumZoomScale = 1.0
//        webView.scrollView.minimumZoomScale = 0.5
        self.webViewContainerView.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: self.webViewContainerView.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: self.webViewContainerView.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: self.webViewContainerView.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.webViewContainerView.bottomAnchor).isActive = true

        return webView;
    }
    
    func loadURL(_ url: String) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            if let webView = self.mainWebView {
                if Thread.isMainThread {
                    webView.load(request)
                } else {
                    DispatchQueue.main.async {
                        webView.load(request)
                    }
                }
            }
        }
    }
}

extension DetailWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
    }
    
    // WKNavigationDelegate - 보안으로 인해 웹페이지가 뜨지 않을 때
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust  else {
            completionHandler(.useCredential, nil)
            return
        }
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
        
    }
}

