//
//  TagWorksPopup.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 2/18/25.
//

import Foundation
import UIKit
import WebKit

@objc final public class TagWorksPopup: NSObject {
    
    // MARK: - 싱글톤 객체 생성 및 반환
    @objc static public let sharedInstance = TagWorksPopup()
    
    private override init() {
        super.init()
    }
    
    private var popupViewController: UIViewController?
    private var currentViewController: UIViewController?
    private var detailWebViewController: DetailWebViewController?
    private var isPopupAnimating = false
    
    private var bannerView: UIView?
//    private var defaultWebView = WKWebView()
//    private var onCMSBannerWebView = WKWebView()
    private var defaultWebView: UIImageView?
    private var onCMSBannerWebView: WKWebView?
    private var webViewManager: WebViewManager!
    
    // ======================================================
    
    //    "cust_id": "testuser",
    //    "rcmd_area_cd": "NEW_AREA_1"
    
    @objc public func onCMSPopup(
        onCmsUrl: String, cust_id: String, rcmd_area_cd: String, owner: UIViewController
    ) {
        currentViewController = owner
        
        let vstor_id = TagWorks.sharedInstance.visitorId
        let siteId = TagWorks.sharedInstance.siteId ?? ""
        var cntn_id = ""
        let components = siteId.split(separator: ",")
        // 키와 값 추출
        if components.count > 0 {
            cntn_id = String(components[1])
        }
        let restApiManager = RestApiManager()
        restApiManager.onCMSBridgePopup(
            onCmsUrl: onCmsUrl, cust_id: cust_id, rcmd_area_cd: rcmd_area_cd, vstor_id: vstor_id, cntn_id: cntn_id
        ) { success, data in
            if success {
                let parameters: [String: Any] = [
                    "cust_id": cust_id,
                    "rcmd_area_cd": rcmd_area_cd,
                    "vstor_id": vstor_id,
                    "cntn_id": cntn_id
                ]
                let requestUrl = onCmsUrl + "?" + parameters.map { key, value in
                    return "\(key)=\(value)"
                }.joined(separator: "&")
                
                DispatchQueue.main.async {
                    self.popupViewController = WebPopupViewController(
                        cust_id: cust_id,
                        rcmd_area_cd: rcmd_area_cd,
                        requestUrl: requestUrl,
                        jsonData: data as! [String: Any])
                    
                    // 뒷 배경이 보이도록 설정
                    self.popupViewController?.modalPresentationStyle =
                        .overCurrentContext
                    
                    if let tempDic = data as? [String: Any] {
                        let styleString = tempDic["style"] as? String
                        var styleDic: [String: Any] = [:]
                        if let styleString = styleString {
                            styleDic =
                            try! JSONSerialization.jsonObject(with: styleString.data(using: .utf8)!, options: []) as! [String: Any]
                        }
                        
                        if styleDic["popupType"] as! String == "S" {
                            // 바텀 슬라이드
                            self.isPopupAnimating = true
                        } else if styleDic["popupType"] as! String == "C" {
                            // 센터 팝업
                            self.isPopupAnimating = false
                        } else {
                            // 전체페이지
                            self.isPopupAnimating = true
                        }
                    }
                }
            } else {
                // success == false 인 경우,
            }
        }
    }
    
    @objc public func onCMSPopupBanner(
        onCmsUrl: String, cust_id: String, rcmd_area_cd: String, bannerView: UIView, defaultPngImageName: String
    ) {
        currentViewController = nil
        
        self.bannerView = bannerView
        createBannerWebView(defaultImageName: defaultPngImageName)
        
        let vstor_id = TagWorks.sharedInstance.visitorId
        let siteId = TagWorks.sharedInstance.siteId ?? ""
        var cntn_id = ""
        let components = siteId.split(separator: ",")
        // 키와 값 추출
        if components.count > 0 {
            cntn_id = String(components[1])
        }
        let restApiManager = RestApiManager()
        restApiManager.onCMSBridgePopupBanner(
            onCmsUrl: onCmsUrl, cust_id: cust_id, rcmd_area_cd: rcmd_area_cd, vstor_id: vstor_id, cntn_id: cntn_id
        ) { success, data in
            if success {
                DispatchQueue.main.async {
                    if let htmlString = data as? String {
                        self.webViewManager = WebViewManager(webView: self.onCMSBannerWebView!)
                        self.webViewManager.webViewDelegate = TagWorksPopup.sharedInstance
                        
                        self.onCMSBannerWebView!.loadHTMLString(htmlString, baseURL: nil)
                    }
                }
            } else {
                // success == false 인 경우,
            }
        }
    }
    
    func createBannerWebView(defaultImageName: String) {
        if let bannerView = bannerView {
            print("bannerView Size: \(bannerView.bounds.width) x \(bannerView.bounds.height)")
            if self.defaultWebView == nil {
//                self.defaultWebView = WKWebView()
                self.defaultWebView = UIImageView()
            }
            defaultWebView!.frame = CGRect(x: 0, y: 0, width: bannerView.bounds.width, height: bannerView.bounds.height)
            //            defaultWebView.translatesAutoresizingMaskIntoConstraints = false
            defaultWebView!.contentMode = .scaleToFill
            defaultWebView!.backgroundColor = .clear
//            setWebViewDefaultContents(webView: defaultWebView!, pngImageName: defaultImageName)
            defaultWebView!.image = UIImage(named: defaultImageName)
            bannerView.addSubview(defaultWebView!)
            
            if self.onCMSBannerWebView == nil {
                self.onCMSBannerWebView = WKWebView()
            }
            onCMSBannerWebView!.frame = CGRect(x: 0, y: 0, width: bannerView.bounds.width, height: bannerView.bounds.height)
            //            onCMSBannerWebView.translatesAutoresizingMaskIntoConstraints = false
            onCMSBannerWebView!.contentMode = .scaleToFill
            onCMSBannerWebView!.backgroundColor = .clear
            onCMSBannerWebView!.isHidden = true
            
            bannerView.addSubview(onCMSBannerWebView!)
            bannerView.addSubview(defaultWebView!)
        }
    }
    
    @objc public func setWebViewDefaultContents(webView: WKWebView, pngImageName: String) {
        guard pngImageName.count > 0 else { return }
        guard let url = Bundle.main.url(forResource: pngImageName, withExtension: "png") else { return }
        let directoryURL = url.deletingLastPathComponent()
        //        webView.loadFileURL(url, allowingReadAccessTo: directoryURL)
        
        let htmlString = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
        </head>
        <body style="margin:0;padding:0;text-align:center;">
            <img src="\(url.absoluteString)" style="max-width:100%; height:auto;">
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: directoryURL)
    }
    
    @objc public func presentDetailWebViewcontroller(loadUrl: String, owner: UIViewController) {
        detailWebViewController = DetailWebViewController(nibName: "DetailWebViewController", bundle: Bundle(for: TagWorksPopup.self))
        guard let detailWebViewController = detailWebViewController else { return }
        detailWebViewController.requestUrl = loadUrl
        detailWebViewController.isModal = true
        
        let navigationController = UINavigationController(rootViewController: detailWebViewController)
        let closeButton = UIBarButtonItem(title: "닫기", style: .plain, target: self, action: #selector(closeTapped))
        closeButton.tintColor = UIColor.white
        detailWebViewController.navigationItem.rightBarButtonItem = closeButton
        
        owner.present(navigationController, animated: true)
    }
    
    @objc public func pushDetailWebViewcontroller(loadUrl: String, owner: UINavigationController) {
        detailWebViewController = DetailWebViewController(nibName: "DetailWebViewController", bundle: Bundle(for: TagWorksPopup.self))
        guard let detailWebViewController = detailWebViewController else { return }
        detailWebViewController.requestUrl = loadUrl
        detailWebViewController.isModal = false
        
        owner.pushViewController(detailWebViewController, animated: true)
    }
    
    // 닫기 버튼 눌렀을 때 실행될 함수
    @objc private func closeTapped() {
        if let detailWebViewController = detailWebViewController {
            detailWebViewController.dismiss(animated: true)
        }
    }
    
    
    
    
    
    public func onCMSPopupCenter(
        onCmsUrl: String, cust_id: String, rcmd_area_cd: String, _ owner: UIViewController
    ) {
        currentViewController = owner
        
        let vstor_id = TagWorks.sharedInstance.visitorId
        let siteId = TagWorks.sharedInstance.siteId ?? ""
        var cntn_id = ""
        let components = siteId.split(separator: ",")
        // 키와 값 추출
        if components.count > 0 {
            cntn_id = String(components[1])
        }
        
        //        href="obzenapp://webviewurl=https%3A%2F%2Fwww.obzen.com%2F
        let viewHtml: String = """
            <html>
             <head>
              <meta http-equiv="Content-Type" content="'text/html; charset=UTF-8">
              <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1.0">
              <link rel="stylesheet" href="https://dxlab.obzen.com/html/jrecommend/oncms//css/rolling.css">
              <link rel="stylesheet" href="https://dxlab.obzen.com/html/jrecommend/oncms//css/popup.css">
              <link rel="stylesheet" href="https://dxlab.obzen.com/html/jrecommend/oncms//css/obz.rcmd.font.css">
              <script>function addElementView(){var e=document.querySelectorAll("[rcmd_item_id]"),t=new IntersectionObserver(function(e,t){e.forEach(function(e){e.isIntersecting&&(e.target.classList.add("visible"),onCMSEvent(e.target,"ElementVisibility_onCMS"),t.unobserve(e.target))})},{threshold:.5});e.forEach(function(e){t.observe(e)})}function onCMSEvent(e,t){var i=decodeURIComponent("%E2%88%9E"),r=decodeURIComponent("%E2%89%A1"),n="e_c="+["obz_client_date"+r+new Date().toISOString(),"obz_trg_type"+r+t,"obz_preview"+r+"0","ozvid"+r+"{{vstor_id}}","excmp_id"+r+(e.getAttribute("excmp_id")||""),"area_snrio_id"+r+(e.getAttribute("area_snrio_id")||""),"rcmd_rule_id"+r+(e.getAttribute("rcmd_rule_id")||""),"rcmd_area_cd"+r+(e.getAttribute("rcmd_area_cd")||""),"rcmd_item_id"+r+(e.getAttribute("rcmd_item_id")||"")].join(i),a="url="+encodeURIComponent(window.location.href),o="urlref="+encodeURIComponent(document.referrer);obzenLogEvent(n+"&"+a+"&"+o+"&e_a=obzen")}function obzenLogEvent(e){var t={},i=decodeURIComponent("%E2%88%9E"),r=decodeURIComponent("%E2%89%A1"),n=new Date,a="",o=(10>n.getHours()?"0":"")+n.getHours()+(10>n.getMinutes()?"0":"")+n.getMinutes()+(10>n.getSeconds()?"0":"")+n.getSeconds();e.split("&").forEach(function(e){var n=e.split("="),a=n[0],s=n[1];a&&("e_c"==a&&(s+=i+"oncms_time"+r+o),t[decodeURIComponent(a)]=decodeURIComponent(s?s.replace(/\\+/g," "):""))}),void 0!=window.webkit&&void 0!=window.webkit.messageHandlers&&void 0!=window.webkit.messageHandlers.TagWorksJSInterfaces&&(a="IOS"),void 0!=window.TagWorksJSInterfaces&&(a="Android"),void 0!=window.ReactNativeWebView&&(a="React"),"IOS"===a&&window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.TagWorksJSInterfaces.postMessage(t),"Android"===a&&window.TagWorksJSInterfaces&&window.TagWorksJSInterfaces.TagWorksWebEvent(JSON.stringify(t)),"React"===a&&window.ReactNativeWebView&&window.ReactNativeWebView.postMessage(JSON.stringify(t))}</script>
             </head>
             <body>
              <style> .list > * { border-radius: 0px; overflow: hidden; margin-bottom: 0px;}  .wrap .banner-dot { width: 6px !important; height: 6px !important;}  .wrap .banner-dot-pager {} .wrap .banner-info {display:none;} .wrap { background : #ffffff; } </style>
              <div class="wrap">
               <div class="list">
                <div id="lpmobile" obz-br="0" class="content-container lpmobile-content" style="position:relative; background:rgb(255, 228, 83); width:300px; height:250px;" onclick="onCMSEvent(this, 'AllElementsClick_Elem_onCMS')" rcmd_area_cd="POPUP_TEST_AREA" excmp_id="E250317901_10003_0001" area_snrio_id="E250317901_10001" rcmd_rule_id="E250317901_10002" rcmd_item_id="4004040">
                 <a style="position:absolute;width:100%;height:100%;" target="blank" href="https://www.naver.com"></a>
                 <div id="mimage1" class="lp-ctl" data-alias="이미지1" data-type="image" style="position: absolute; left: 80px; top: 70px; width: 220px; height: 180px; box-sizing: border-box; pointer-events: none;" data-x="80" data-y="70">
                  <img style="position: absolute; left: 0px; top: 0px; width: 100%; height: 100%;" imagename="[2000101] 계좌신고" src="./html/jrecommend/oncms/img/2000101_hQbYY.png"><a class="obz-lp-link" style="position: absolute; left: 0px; top: 0px; width: 100%; height: 100%; text-decoration: none;"></a>
                 </div>
                 <div id="mlabel1" class="lp-ctl" data-alias="텍스트1" data-type="label" style="position: absolute; left: 20px; top: 60px; width: 200px; height: 80px; box-sizing: border-box; background: rgba(0, 0, 0, 0); border-color: rgb(68, 68, 68); border-radius: 0px; pointer-events: none;" data-x="20" data-y="60">
                  <div class="text-area" style="overflow: hidden; font-family: var(--obz-rcmd-base-font); font-size: var(--obz-rcmd-base-font-size); overflow-wrap: break-word;">
                   <p style="line-height: 1.5; margin: 0px;"><strong style="font-size: 22px;">가맹점 계좌 등록하고</strong></p>
                   <p style="line-height: 1.5; margin: 0px;"><strong style="font-size: 22px;">사은품받자!</strong></p>
                  </div>
                 </div>
                 <div id="mlabel2" class="lp-ctl" data-alias="텍스트2" data-type="label" style="position: absolute; left: 20px; top: 20px; width: 60px; height: 18px; box-sizing: border-box; background: rgb(255, 247, 227); border-color: rgb(68, 68, 68); border-radius: 15px; pointer-events: none;" data-x="20" data-y="20">
                  <div class="text-area" style="overflow: hidden; font-family: var(--obz-rcmd-base-font); font-size: var(--obz-rcmd-base-font-size); overflow-wrap: break-word;">
                   <p style="text-align: center; margin: 0px;"><span style="font-size: 14px;">Event</span></p>
                  </div>
                 </div>
                 <div id="mlabel3" class="lp-ctl" data-alias="텍스트3" data-type="label" style="position: absolute; left: 20px; top: 150px; width: 200px; height: 40px; box-sizing: border-box; background: rgba(0, 0, 0, 0); border-color: rgb(68, 68, 68); border-radius: 0px; pointer-events: none;" data-x="20" data-y="150">
                  <div class="text-area" style="overflow: hidden; font-family: var(--obz-rcmd-base-font); font-size: var(--obz-rcmd-base-font-size); overflow-wrap: break-word;">
                   <p style="margin: 0px;">2025-03-11 ~ 2025-11-30</p>
                  </div>
                 </div>
                </div>
               </div>
               <div class="banner-dot-pager"></div>
               <div class="banner-info">
                <div class="banner-btn">
                 <svg xmlns="http://www.w3.org/2000/svg" height="20px" viewBox="0 0 24 24" width="20px">
                  <path d="M8 6.82v10.36c0 .79.87 1.27 1.54.84l8.14-5.18c.62-.39.62-1.29 0-1.69L9.54 5.98C8.87 5.55 8 6.03 8 6.82z" />
                 </svg>
                 <svg xmlns="http://www.w3.org/2000/svg" height="20px" viewBox="0 0 24 24" width="20px">
                  <path d="M8 19c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2s-2 .9-2 2v10c0 1.1.9 2 2 2zm6-12v10c0 1.1.9 2 2 2s2-.9 2-2V7c0-1.1-.9-2-2-2s-2 .9-2 2z" />
                 </svg>
                </div>
                <div class="banner-idx"></div>
               </div>
              </div>
              <script src="https://dxlab.obzen.com/html/jrecommend/oncms//js/rolling.js"></script>
              <script>var bannerDelay = 4000; initTemplate();document.addEventListener('DOMContentLoaded', function(){addElementView();});</script>
             </body>
            </html>
            """
        
        let styleValue: String = """
            {
            "webViewWidth":320,
            "webViewHeight":260,
            "webViewRadius":15,
            "webViewBgColor":"#ffffff",
            "webViewBgAlpha":0.13,
            "cardWidth":320,
            "cardHeight":260,
            "bgcloseOption":"1",
            "dupDisplayDelay":0,
            "popupType":"C",
            "popupTitleUse":"0",
            "popupTitle":"고객님께 알립니다",
            "popupTitleHeight":30,
            "popupTitleTextAlign":"center",
            "popupTitleFontSize":15,
            "popupTitleFontColor":"#707070",
            "popupTitleBgColor":"#FFFFFF",
            "closeBtnGrpType":"2",
            "closeBtnGrpHeight":40,
            "closeBtnGrpFontSize":15,
            "closeOptBtnType":"1",
            "closeOptBtnFontColor":"#ffffff",
            "closeOptBtnBgColor":"#ff5018",
            "closeBtnFontColor":"#414141",
            "closeBtnBgColor":"#ffffff",
            "contListType":"",
            "contType":"ROLLING",
            "cardRadius":0,
            "cardMargin":0,
            "backgroundColor":"#ffffff",
            "useRollingIndex":"0",
            "usePaging":"1",
            "pagePosition":"",
            "pageTop":0,
            "pageBottom":0,
            "pageLeft":0,
            "pageRight":0,
            "dotSize":6,
            "rollingSpeed":4000,
            "listTitle":"",
            "listTitleIcon":"",
            "listTitleTextAlign":"center",
            "listTitleFontSize":"10px",
            "listTitleFontColor":"#555555",
            "autoCloseSec":0,
            "closeBtnPosition":"bottom"
            }
            """
        
        let parameters: [String: Any] = [
            "cust_id": cust_id,
            "rcmd_area_cd": rcmd_area_cd,
            "vstor_id": vstor_id,
            "cntn_id": cntn_id
        ]
        let requestUrl = onCmsUrl + "?" + parameters.map { key, value in
            return "\(key)=\(value)"
        }.joined(separator: "&")
        
        
        DispatchQueue.main.async {
            let dataDic: [String: Any] = [
                "view": viewHtml, "style": styleValue,
            ]
            
            //            self.popupViewController = WebPopupViewController(jsonData: data as! [String: Any])
            //            self.popupViewController = WebPopupViewController(cust_id: cust_id, rcmd_area_cd: rcmd_area_cd, requestUrl: "onCMSPopupCenter", jsonData: dataDic)
            self.popupViewController = WebPopupViewController(
                cust_id: cust_id,
                rcmd_area_cd: rcmd_area_cd,
                requestUrl: requestUrl,
                jsonData: dataDic)
            
            // 뒷 배경이 보이도록 설정
            self.popupViewController?.modalPresentationStyle = .overCurrentContext
            
            let styleString = dataDic["style"] as? String
            var styleDic: [String: Any] = [:]
            if let styleString = styleString {
                styleDic =
                try! JSONSerialization.jsonObject(
                    with: styleString.data(using: .utf8)!, options: [])
                as! [String: Any]
            }
            
            if styleDic["popupType"] as! String == "S" {
                // 바텀 슬라이드
                self.isPopupAnimating = true
            } else if styleDic["popupType"] as! String == "C" {
                // 센터 팝업
                self.isPopupAnimating = false
            } else {
                // 전체페이지
                self.isPopupAnimating = true
            }
            
            if let webPopupViewcontroller = self.popupViewController as? WebPopupViewController
            {
                webPopupViewcontroller.backgroundAlpha = 0.5
                //                        webPopupViewcontroller.isPopupAnimating = true
                //                        webPopupViewcontroller.showCenterPopup()
                //                        webPopupViewcontroller.showBottomPopup()
                //                        webPopupViewcontroller.showPagePopup()
            }
        }
    }
}

extension TagWorksPopup: WebViewManagerDelegate {
    
    func webViewDidFinishLoad(_ webView: WKWebView) {
        // 배너인 경우, 웹뷰 체인지 후 끝!!
        if bannerView != nil {
            defaultWebView!.isHidden = true
            onCMSBannerWebView!.isHidden = false
//            return
        }
        
//        if currentViewController == nil {
//            // rootViewController를 가져오기
//            guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
//                return
//            }
//            currentViewController = rootViewController
//        }
        
        // 현재 보여지고 있는 ViewController가 유효한지 체크
        guard let viewController = currentViewController,
            viewController.isViewLoaded, viewController.view.window != nil
        else {
            print("ViewController is not visible, cannot show popup.")
            return
        }

        // 팝업을 띄우기 위해 present
        if let popupViewController = self.popupViewController as? WebPopupViewController {
            if popupViewController.isShowCheckDisplayShow() {
                // 동일 팝업 노출 딜레이 체크
                if popupViewController.isShowCheckDisplayDelay() {
                    viewController.present(popupViewController, animated: isPopupAnimating, completion: nil)
                } else {
                    print("동일 팝업 노출 딜레이 타임 : \(popupViewController.displayDelayDate!)")
                }
            } else {
                print("팝업 노출 보여질 타임 : \(popupViewController.displayShowDate!)")
            }
        }
    }

    func webViewDidFailLoad(_ webView: WKWebView, withError error: Error) {
        print(
            "💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] WebView Loding Error:"
                + error.localizedDescription)
    }
    
    func webPopupViewControllerDismiss() {
        popupViewController?.dismiss(animated: false)
    }
    
    func showDetailWebViewContoller(url: URL) {
        popupViewController?.dismiss(animated: false)
        
        guard let ownerViewController = currentViewController else { return }
        presentDetailWebViewcontroller(loadUrl: url.absoluteString, owner: ownerViewController)
    }
}
