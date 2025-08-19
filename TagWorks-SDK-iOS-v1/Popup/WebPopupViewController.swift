//
//  WebPopupViewController.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 2/18/25.
//

import UIKit
@preconcurrency import WebKit

public class WebPopupViewController: UIViewController {
    private var cust_id: String!
    private var rcmd_area_cd: String!
    private var requestUrl: String!
    
    private var jsonDic: [String: Any]! = [:]
    private var styleDic: [String: Any]!
    private var viewHtmlString: String?
    
    private var webViewManager: WebViewManager!
    private var containerView: UIView = UIView(frame: .zero)
//    private var webView: WKWebView = WKWebView(frame: .zero)
    private var titleLabel = PaddedLabel()
    private var webView: WKWebView
    private var dimBackgroundView: UIView = UIView(frame: .zero)

    private let closeButton = UIButton(type: .custom)
    private let closeOptionButton = UIButton(type: .custom)
    
    var popupStyle: WebPopupStyle!
    
    public var backgroundAlpha: CGFloat = 0.5 {
        didSet {
            dimBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(backgroundAlpha)
        }
    }
    public var isPopupAnimating = false

    private let userDefaults = UserDefaults(suiteName: "TagWorks_onCMS")!
    // 동일 영역 팝업 표시 딜레이 시간 (10~30초)
    public var displayDelayDate: String?
    {
        get {
            return userDefaults.string(forKey: self.rcmd_area_cd + "_delay") ?? ""
        }
        set {
            userDefaults.setValue(newValue, forKey: self.rcmd_area_cd + "_delay")
            userDefaults.synchronize()
        }
    }
    // 동일 영역 팝업 보여지는 시간 (1일, 7일)
    public var displayShowDate: String?
    {
        get {
            return userDefaults.string(forKey: self.rcmd_area_cd + "_not_show") ?? ""
        }
        set {
            userDefaults.setValue(newValue, forKey: self.rcmd_area_cd + "_not_show")
            userDefaults.synchronize()
        }
    }
    
    public init(cust_id: String, rcmd_area_cd: String, requestUrl: String, jsonData: Any) {
        self.cust_id = cust_id
        self.rcmd_area_cd = rcmd_area_cd
        self.requestUrl = requestUrl
        
        if let tempDic = jsonData as? [String : Any] {
            self.jsonDic = tempDic
        }
        
        // Popup WebView 생성
        let contentController = WKUserContentController()
        // Swift에 JavaScript 인터페이스 연결
        TagWorks.sharedInstance.webViewInterface.addTagworksWebInterface(contentController)
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        
        super.init(nibName: nil, bundle: nil)
        
        parseStyle(from: jsonDic)
        self.viewHtmlString = jsonDic["view"] as? String
        
        popupStyle = WebPopupStyle(styleJson: self.styleDic)
        
//        self.displayDelayDate = ""
        // 팝업 창 스타일을 위한 설정
        self.view.backgroundColor = .clear
        
        initializeViews()

        // Dim 처리된 백그라운드 뷰
        dimBackgroundView.frame = self.view.bounds
        
        // 배경을 탭했을 때 팝업을 닫기 위한 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        dimBackgroundView.addGestureRecognizer(tapGesture)
        
        if popupStyle.popupType == "S" {
            // 바텀 슬라이드
            isPopupAnimating = true
            showBottomPopup()
        } else if popupStyle.popupType == "C" {
            // 센터 팝업
            isPopupAnimating = false
            showCenterPopup()
        } else {
            // 전체페이지
            isPopupAnimating = true
            showPagePopup()
        }
        
        loadHTMLStringOnWebView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Response 정보로부터 style 정보를 가져옴.
//    private func parseStyle(from tempDic: [String: Any]) -> [String: Any] {
    private func parseStyle(from tempDic: [String: Any]) {
        guard let styleString = tempDic["style"] as? String,
              let data = styleString.data(using: .utf8),
              let style = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            TagWorks.log("❌ 팝업 스타일 정보를 파싱할 수 없습니다.")
            return
        }
        
        self.styleDic = style
        TagWorks.log("팝업 스타일 정보:\n\(style.map { "• \($0.key): \($0.value)" }.joined(separator: "\n"))")
//        return style
    }

    func initializeViews() {
        // Dim 처리된 백그라운드 뷰
        // 스타일값 "webViewBgAlpha":0,
        dimBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(popupStyle.webViewBgAlpha)
        
        dimBackgroundView.tag = 999  // 나중에 이 tag를 통해 dim background를 찾고 삭제할 수 있음
        self.view.addSubview(dimBackgroundView)
        
        // 컨테이너 뷰 초기화
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        self.view.addSubview(containerView)
        
        // 타이틀 바 초기화
        // 라벨이 뷰에 추가되도록 하기 전에 Auto Layout 활성화
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 웹뷰 초기화
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.bounces = false
        webView.backgroundColor = UIColor(hex: popupStyle.webViewBgColor)
//        webView.navigationDelegate = self     // webViewManager에서 navigationDelegate를 사용하기 때문에 여기선 소용이 없음
        if #available(iOS 13.0.0, *) {
            webView.uiDelegate = self
        }
        containerView.addSubview(webView)
        
        // WebViewManager 초기화
        webViewManager = WebViewManager(webView: webView)
        webViewManager.webViewDelegate = TagWorksPopup.sharedInstance
        
        // Buttons
        closeButton.frame = CGRect(x: 0, y: 0, width: 150, height: 50)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.isHidden = false
        containerView.addSubview(closeButton)
        
        closeOptionButton.frame = CGRect(x: 0, y: 0, width: 150, height: 50)
        closeOptionButton.translatesAutoresizingMaskIntoConstraints = false
        closeOptionButton.isHidden = true
        containerView.addSubview(closeOptionButton)
    }
    
    func loadHTMLStringOnWebView() {
        webViewManager = WebViewManager(webView: webView)
        webViewManager.webViewDelegate = TagWorksPopup.sharedInstance
        
        if let popupType = self.jsonDic["ex_meth"] as? String {
            if popupType == "survey" {
                if let url = self.jsonDic["url"] as? String {
                    let request = URLRequest(url: URL(string: url)!)
                    webView.load(request)
                    return
                }
            }
        }
        
        if let htmlString = self.viewHtmlString {
            // baseURL - HTML 내에서 CSS 파일이나 리소스를 사용할 때 상대 경로가 되는 기준 경로
            webView.loadHTMLString(htmlString, baseURL: URL(string: self.requestUrl.urlEncodedForQuery))
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Add your custom code here
        // 자동 팝업 닫기
        if let autoCloseSec = popupStyle.autoCloseSec {
            if autoCloseSec > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(autoCloseSec)) {
                    self.dismiss(animated: self.isPopupAnimating)
                }
            }
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Add your custom code here
        closeForcePopup()
    }
    
    override public func viewDidLayoutSubviews() {
        
    }
    
    // MARK: 중앙 다이얼로그 팝업
    @objc func showCenterPopup() {
        // 팝업을 위한 웹뷰 생성
        createWebView(type: InAppPopupType.center.rawValue)
        
        if popupStyle.popupTitleUse == "1" {
            createTitleView()
        }
        
        createPopupButton()
        
        // 버튼 크기 확인하기
        self.view.layoutIfNeeded() // 레이아웃 갱신
    }
    
    // MARK: 바텀시트 다이얼로그 팝업
    @objc func showBottomPopup() {
        // 팝업을 위한 웹뷰 생성
        createWebView(type: InAppPopupType.bottom.rawValue)
//
        if popupStyle.popupTitleUse == "1" {
            createTitleView()
        }
        
        createPopupButton()
        
        // 버튼 크기 확인하기
        self.view.layoutIfNeeded() // 레이아웃 갱신
    }
    
    // MARK: 전체 페이지 팝업
    @objc func showPagePopup() {
        
        // 팝업을 위한 웹뷰 생성
        createWebView(type: InAppPopupType.page.rawValue)
        
        if popupStyle.popupTitleUse == "1" {
            createTitleView()
        }
        
        createPopupButton()
        
        // 버튼 크기 확인하기
        self.view.layoutIfNeeded() // 레이아웃 갱신
    }
    
    private func createWebView(type: Int) {
        // 웹뷰 스타일 속성값
//        "webViewWidth":320,
//        "webViewHeight":350,
//        "webViewRadius":15,
        
        switch (type) {
            case InAppPopupType.center.rawValue:
                let containerViewWidth = popupStyle.screenWidth - popupStyle.popupSideMargin * 2
                let newWebViewHeight: CGFloat = popupStyle.getCalcNewWebViewHeight(currentWidth: containerViewWidth)
                var newTitleViewHeight: CGFloat = popupStyle.getCalcNewTitleViewHeight(currentWidth: containerViewWidth)
                if popupStyle.popupTitleUse == "0" {
                    newTitleViewHeight = 0
                }
                var newCloseBtnGrpHeight: CGFloat = popupStyle.getCalcNewCloseBtnGrpHeight(currentWidth: containerViewWidth)
                if popupStyle.closeBtnPosition == "top" && newCloseBtnGrpHeight == 0 {
                    newCloseBtnGrpHeight = popupStyle.getCalcNewTopCloseBtnHeight(currentWidth: containerViewWidth) + 20
                }
                let containerViewHeight: CGFloat = newWebViewHeight + newTitleViewHeight + newCloseBtnGrpHeight
                
                // 팝업 제약 조건 설정 (화면 가운데로 배치)
                NSLayoutConstraint.activate([
                    containerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                    containerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                    containerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: popupStyle.popupSideMargin),
                    containerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -popupStyle.popupSideMargin),
                    containerView.heightAnchor.constraint(equalToConstant: containerViewHeight),
                    
                    webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    webView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: popupStyle.closeBtnPosition == "top" ? newTitleViewHeight + newCloseBtnGrpHeight : newTitleViewHeight),
                    webView.heightAnchor.constraint(equalToConstant: newWebViewHeight)
                ])
                break
            case InAppPopupType.bottom.rawValue:
                let containerViewWidth = popupStyle.screenWidth
                let newWebViewHeight: CGFloat = popupStyle.getCalcNewWebViewHeight(currentWidth: containerViewWidth)
                var newTitleViewHeight: CGFloat = popupStyle.getCalcNewTitleViewHeight(currentWidth: containerViewWidth)
                if popupStyle.popupTitleUse == "0" {
                    newTitleViewHeight = 0
                }
                var newCloseBtnGrpHeight: CGFloat = popupStyle.getCalcNewCloseBtnGrpHeight(currentWidth: containerViewWidth)
                if popupStyle.closeBtnPosition == "top" && newCloseBtnGrpHeight == 0 {
                    newCloseBtnGrpHeight = popupStyle.getCalcNewTopCloseBtnHeight(currentWidth: containerViewWidth) + 20
                } else if popupStyle.closeBtnPosition == "intop" {
                    newCloseBtnGrpHeight = 0
                }
                
                let containerViewHeight: CGFloat = newWebViewHeight + newTitleViewHeight + newCloseBtnGrpHeight
                
                // 팝업 제약 조건 설정 (화면 바닥으로 배치)
                if #available(iOS 11.0, *) {
                    NSLayoutConstraint.activate([
                        containerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        containerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        containerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                        containerView.heightAnchor.constraint(equalToConstant: containerViewHeight),
                        
                        webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                        webView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: popupStyle.closeBtnPosition == "top" ? newTitleViewHeight + newCloseBtnGrpHeight : newTitleViewHeight),
                        webView.heightAnchor.constraint(equalToConstant: newWebViewHeight)
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        containerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        containerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        containerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                        containerView.heightAnchor.constraint(equalToConstant: containerViewHeight),

                        webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                        webView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: popupStyle.closeBtnPosition == "top" ? newTitleViewHeight + newCloseBtnGrpHeight : newTitleViewHeight),
                        webView.heightAnchor.constraint(equalToConstant: newWebViewHeight)
                    ])
                }
                break
            case InAppPopupType.page.rawValue:
                let containerViewWidth = popupStyle.screenWidth
                var newTitleViewHeight: CGFloat = popupStyle.getCalcNewTitleViewHeight(currentWidth: containerViewWidth)
                if popupStyle.popupTitleUse == "0" {
                    newTitleViewHeight = 0
                }
                var newCloseBtnGrpHeight: CGFloat = popupStyle.getCalcNewCloseBtnGrpHeight(currentWidth: containerViewWidth)
                if popupStyle.closeBtnPosition == "top" && newCloseBtnGrpHeight == 0 {
                    newCloseBtnGrpHeight = popupStyle.getCalcNewTopCloseBtnHeight(currentWidth: containerViewWidth) + 20
                }
                
                // 팝업 제약 조건 설정 (화면 전체로 배치)
                if #available(iOS 11.0, *) {
                    NSLayoutConstraint.activate([
                        containerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        containerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        containerView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                        containerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                        
                        webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                        webView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: popupStyle.closeBtnPosition == "top" ? newTitleViewHeight + newCloseBtnGrpHeight : newTitleViewHeight),
                        webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: popupStyle.closeBtnPosition == "top" ? 0 : -newCloseBtnGrpHeight)
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        containerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        containerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        containerView.topAnchor.constraint(equalTo: self.view.topAnchor),
                        containerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                        
                        webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                        webView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: popupStyle.closeBtnPosition == "top" ? newTitleViewHeight + newCloseBtnGrpHeight : newTitleViewHeight),
                        webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: popupStyle.closeBtnPosition == "top" ? 0 : -newCloseBtnGrpHeight),
                    ])
                }
                break
            default:
                break
        }
        
        // Auto Layout 적용 후 강제로 즉시 갱신하여 다시 그려지도록 함
        containerView.layoutIfNeeded()
        
        // 타이틀뷰를 사용하지 않을 경우, 웹뷰에 radius 처리
        if popupStyle.popupTitleUse == "0" {
            // 상단 radius
            let ratioRadius: CGFloat = popupStyle.ratioWebviewCornerRadius(currentWidth: webView.bounds.width)
            webView.layer.masksToBounds = true
            if #available(iOS 11.0, *) {
                webView.layer.cornerRadius = ratioRadius
                if type == InAppPopupType.center.rawValue {
                    webView.layer.maskedCorners = popupStyle.closeBtnPosition == "top" ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner ]
                                                                                       : [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Top right corner, Top left corner respectively
                } else {
                    webView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Top right corner, Top left corner respectively
                }
            } else {
                if type == InAppPopupType.center.rawValue {
                    webView.roundCorners(corners: popupStyle.closeBtnPosition == "top" ? [.topLeft, .topRight, .bottomLeft, .bottomRight] : [.topLeft, .topRight], radius: ratioRadius)
                } else {
                    webView.roundCorners(corners: [.topLeft, .topRight], radius: ratioRadius)  // 상단 왼쪽, 상단 오른쪽 모서리만 둥글게
                }
            }
        }
        
        // webview inspector 가능하도록 설정
        if #available(iOS 16.4, *) {
            #if DEBUG
            self.webView.isInspectable = true  // webview inspector 가능하도록 설정
            #endif
        }
        
        print("webView size: \(webView.bounds.size)")
    }
    
    // MARK: 팝업 타이틀 뷰 생성
    private func createTitleView() {
        
        // 타이틀뷰 스타일 속성값
//        "popupTitle":"이벤트 알림",
//        "popupTitleHeight":100,
//        "popupTitleTextAlign":"center",
//        "popupTitleFontSize":13,
//        "popupTitleFontColor":"#cdcdcd",
//        "popupTitleBgColor":"#FFFFFF",
//        "webViewRadius":15,
        
        // 라벨 만들기
        let label = titleLabel
        label.frame = CGRect(x: 0, y: 0, width: 100, height: 10)

        let newHeight: CGFloat = popupStyle.getCalcNewTitleViewHeight(currentWidth: webView.bounds.width)
        
        // Auto Layout 제약 설정 (가로, 세로, 중앙 정렬)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: webView.topAnchor, constant: 0),
            label.heightAnchor.constraint(equalToConstant: newHeight)
        ])
        
        // 스타일 설정
        // Auto Layout 적용 후 강제로 즉시 갱신하여 다시 그려지도록 함 - 위치를 변경하면 안됨!!!
        label.layoutIfNeeded()
        
        label.backgroundColor = UIColor(hex: popupStyle.popupTitleBgColor)
        
        // 라벨의 텍스트 설정
        label.text = popupStyle.popupTitle
        
        // 텍스트 정렬 설정 (가운데 정렬)
        var titleAlign: NSTextAlignment = .center
        if popupStyle.popupTitleTextAlign == "left" {
            titleAlign = .left
        } else if popupStyle.popupTitleTextAlign == "right" {
            titleAlign = .right
        }
        label.textAlignment = titleAlign
        
        // 글꼴과 크기 설정
        let ratioFontSize = popupStyle.ratioTitleFontSize(currentWidth: webView.bounds.width)
        label.font = UIFont.systemFont(ofSize: ratioFontSize)
        
        // 텍스트 색상
        label.textColor = UIColor(hex: popupStyle.popupTitleFontColor)
        
        // 상단 radius
        let ratioRadius: CGFloat = popupStyle.ratioWebviewCornerRadius(currentWidth: webView.bounds.width)
        label.roundCorners(corners: [.topLeft, .topRight], radius: ratioRadius)
    }
    
    private func createPopupButton() {
        var buttonCount: Int = 1
//        var buttonType = InAppPopupButtonType.close
        
        if popupStyle.closeBtnGrpType == "2" {
            buttonCount = 2
            self.closeOptionButton.isHidden = false
            
            if popupStyle.closeOptBtnType == "1" {
                // 오늘 하루 보지 않기
//                buttonType = InAppPopupButtonType.closeAndNoShowToday
                closeOptionButton.setTitle("오늘 하루 보지 않기", for: .normal)
            } else if popupStyle.closeOptBtnType == "7" {
                // 일주일간 보지 않기
//                buttonType = InAppPopupButtonType.closeAndNoShowSeven
                closeOptionButton.setTitle("일주일간 보지 않기", for: .normal)
            } else if popupStyle.closeOptBtnType == "0" {
                // 다시 보지 않기
//                buttonType = InAppPopupButtonType.closeAndNoMoreShow
                closeOptionButton.setTitle("다시 보지 않기", for: .normal)
            }
        }
        
        let ratioFontSize = popupStyle.ratioCloseBtnGrpFontSize(currentWidth: webView.bounds.width)
        let ratioHalfFontSize = popupStyle.ratioCloseBtnGrpFontSize(currentWidth: webView.bounds.width / 2)
        
        closeButton.backgroundColor = UIColor(hex: popupStyle.closeBtnBgColor)
        closeButton.setTitle("닫기", for: .normal)
        closeButton.setTitleColor(UIColor(hex: popupStyle.closeBtnFontColor), for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: buttonCount == 1 ? ratioFontSize : ratioHalfFontSize)
        closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        
        closeOptionButton.backgroundColor = UIColor(hex: popupStyle.closeOptBtnBgColor)
        closeOptionButton.setTitleColor(UIColor(hex: popupStyle.closeOptBtnFontColor), for: .normal)
        closeOptionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: ratioHalfFontSize)
        closeOptionButton.addTarget(self, action: #selector(closePopupOption), for: .touchUpInside)
        
        
        // 하단에 닫기 버튼이 존재
        if popupStyle.closeBtnPosition == "bottom" {
            
            // 버튼 레이아웃
            let newButtonHeight = popupStyle.getCalcNewCloseBtnGrpHeight(currentWidth: webView.bounds.width)
            switch (buttonCount) {
                case 1:
                    // 팝업 제약 조건 설정
                    NSLayoutConstraint.activate([
                        // 닫기 버튼의 LayoutConstraint
                        closeButton.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
                        closeButton.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
                        closeButton.topAnchor.constraint(equalTo: webView.bottomAnchor),
                        closeButton.heightAnchor.constraint(equalToConstant: newButtonHeight)
                    ])
                    break
                case 2:
                    // 팝업 제약 조건 설정
                    NSLayoutConstraint.activate([
                        // 오늘 다시 보지 않기 LayoutConstraint
                        closeOptionButton.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
                        closeOptionButton.widthAnchor.constraint(equalTo: webView.widthAnchor, multiplier: 0.5),
                        closeOptionButton.topAnchor.constraint(equalTo: webView.bottomAnchor),
                        closeOptionButton.heightAnchor.constraint(equalToConstant: newButtonHeight),
                        
                        // 닫기 버튼의 LayoutConstraint
                        closeButton.leadingAnchor.constraint(equalTo: closeOptionButton.trailingAnchor),
                        closeButton.widthAnchor.constraint(equalTo: webView.widthAnchor, multiplier: 0.5),
                        closeButton.topAnchor.constraint(equalTo: webView.bottomAnchor),
                        closeButton.heightAnchor.constraint(equalToConstant: newButtonHeight)
                    ])
                    break
                default:
                    break
            }

            closeOptionButton.layoutIfNeeded()
            closeButton.layoutIfNeeded()
            
            // 하단 radius
            if (popupStyle.popupType == "C") {
                let ratioRadius: CGFloat = popupStyle.ratioWebviewCornerRadius(currentWidth: webView.bounds.width)
                if buttonCount == 1 {
                    closeButton.layer.masksToBounds = true
                    closeButton.roundCorners(corners: [.bottomLeft, .bottomRight], radius: ratioRadius)
                } else {
                    closeOptionButton.layer.masksToBounds = true
                    closeOptionButton.roundCorners(corners: .bottomLeft, radius: ratioRadius)
                    
                    closeButton.layer.masksToBounds = true
                    closeButton.roundCorners(corners: .bottomRight, radius: ratioRadius)
                }
            }
        }
        // 닫기 버튼이 위에 노출 (웹뷰 또는 타이틀바 위에)
        else if popupStyle.closeBtnPosition == "top" {
            
            closeOptionButton.backgroundColor = UIColor.clear
            closeOptionButton.contentHorizontalAlignment = .left   // 왼쪽 정렬
            closeOptionButton.setTitleColor(UIColor(hex: "#7B7B7B"), for: .normal)
            
            // 버튼 레이아웃
            let newButtonHeight = popupStyle.getCalcNewTopCloseBtnHeight(currentWidth: webView.bounds.width)
            switch (buttonCount) {
                case 1:
                    // 팝업 제약 조건 설정
                    NSLayoutConstraint.activate([
                        // 닫기 버튼의 LayoutConstraint
                        closeButton.trailingAnchor.constraint(equalTo: webView.trailingAnchor, constant: -12),
                        closeButton.bottomAnchor.constraint(equalTo: popupStyle.popupTitleUse == "1" ? titleLabel.topAnchor : webView.topAnchor, constant: -16),
                        closeButton.widthAnchor.constraint(equalToConstant: newButtonHeight),
                        closeButton.heightAnchor.constraint(equalToConstant: newButtonHeight)
                    ])
                    break
                case 2:
                    // 팝업 제약 조건 설정
                    NSLayoutConstraint.activate([
                        // 오늘 다시 보지 않기 LayoutConstraint
                        closeOptionButton.leadingAnchor.constraint(equalTo: webView.leadingAnchor, constant: 16),
                        closeOptionButton.bottomAnchor.constraint(equalTo: popupStyle.popupTitleUse == "1" ? titleLabel.topAnchor : webView.topAnchor, constant: -16),
                        closeOptionButton.widthAnchor.constraint(equalTo: webView.widthAnchor, multiplier: 0.5),
//                        closeOptionButton.topAnchor.constraint(equalTo: webView.bottomAnchor),
                        closeOptionButton.heightAnchor.constraint(equalToConstant: newButtonHeight),
                        
                        // 닫기 버튼의 LayoutConstraint
                        closeButton.trailingAnchor.constraint(equalTo: webView.trailingAnchor, constant: -12),
                        closeButton.bottomAnchor.constraint(equalTo: popupStyle.popupTitleUse == "1" ? titleLabel.topAnchor : webView.topAnchor, constant: -16),
                        closeButton.widthAnchor.constraint(equalToConstant: newButtonHeight),
                        closeButton.heightAnchor.constraint(equalToConstant: newButtonHeight)
                    ])
                    break
                default:
                    break
            }

            closeOptionButton.layoutIfNeeded()
            closeButton.layoutIfNeeded()
            
            closeButton.backgroundColor = .clear
            let bundle = Bundle(for: WebPopupViewController.self)
//            let image = UIImage(named: "close_white_416.png", in: bundle, compatibleWith: nil)
            let imageName = popupStyle.closeBtnType == "btn1" ? "close-bg-cross.png" : "close-single-cross.png"
            let image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
            
            closeButton.setImage(image, for: .normal)
            closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        }
        // 닫기 버튼이 웹뷰 또는 타이틀 바 안에 노출
        else if popupStyle.closeBtnPosition == "intop" {
            // 옵션 여부 상관 없이 닫기 버튼만 보임.
            self.closeOptionButton.isHidden = true
            
            // 버튼 레이아웃
            let newButtonHeight = popupStyle.getCalcNewTopCloseBtnHeight(currentWidth: webView.bounds.width)
//            let newButtonHeight = 26.0
            // 팝업 제약 조건 설정
            NSLayoutConstraint.activate([
                // 닫기 버튼의 LayoutConstraint
                closeButton.trailingAnchor.constraint(equalTo: webView.trailingAnchor,
                                                      constant: popupStyle.popupTitleUse == "1" ? -12 : -12),
                closeButton.topAnchor.constraint(equalTo: popupStyle.popupTitleUse == "1" ? titleLabel.topAnchor : webView.topAnchor,
                                                 constant: popupStyle.popupTitleUse == "1" ? 8 : 12),
                closeButton.widthAnchor.constraint(equalToConstant: newButtonHeight),
                closeButton.heightAnchor.constraint(equalToConstant: newButtonHeight)
            ])
            
            closeButton.bringSubviewToFront(self.containerView)
            closeButton.backgroundColor = .clear
            let bundle = Bundle(for: WebPopupViewController.self)
            let imageName = popupStyle.closeBtnType == "btn1" ? "close-bg-cross.png" : "close-single-cross.png"
            let image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
            // let image = UIImage(named: "close-single-cross.png", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            
            closeButton.setImage(image, for: .normal)
//            closeButton.tintColor = .white
            closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        }
    }
    
    // MARK: Button Handler
    @objc private func closeForcePopup() {
        dismiss(animated: false, completion: nil)
    }
    
    @objc private func closePopup() {
        // 설정한 동일 팝업 노출 방지 시간 업데이트
        let displayDelayTime = CommonUtil.addedDelaySeconds(seconds: popupStyle.dupDisplayDelay)
        self.displayDelayDate = CommonUtil.dateToString(displayDelayTime)
        dismiss(animated: isPopupAnimating, completion: nil)
        
//        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
//            TagWorksPopup.sharedInstance.presentDetailWebViewcontroller(loadUrl: "https://www.naver.com", owner: rootViewController)
//            TagWorksPopup.sharedInstance.pushDetailWebViewcontroller(loadUrl: "https://www.naver.com", owner: rootViewController as! UINavigationController)
//        }
    }
    
    // 옵션 버튼으로 창을 닫을 때
    @objc private func closePopupOption() {
        
        if popupStyle.closeBtnGrpType == "2" {
            if popupStyle.closeOptBtnType == "1" {
                // 오늘 하루 보지 않기
                let displayNotShowDayDate = CommonUtil.addedDelayDays(days: 1)
                self.displayShowDate = CommonUtil.dateToString(displayNotShowDayDate)
                self.displayDelayDate = ""
            } else if popupStyle.closeOptBtnType == "7" {
                // 일주일간 보지 않기
                let displayNotShowDayDate = CommonUtil.addedDelayDays(days: 7)
                self.displayShowDate = CommonUtil.dateToString(displayNotShowDayDate)
                self.displayDelayDate = ""
            } else if popupStyle.closeOptBtnType == "0" {
                // 다시 보지 않기
                let displayNotShowDayDate = CommonUtil.addedDelayDays(days: LONG_MAX)
                self.displayShowDate = CommonUtil.dateToString(displayNotShowDayDate)
                self.displayDelayDate = ""
            }
        }
        
        dismiss(animated: isPopupAnimating, completion: nil)
    }
    
    @objc func backgroundTapped() {
        if popupStyle.bgCloseOption == "1" {
            closePopup()
        }
    }
    
    public func isShowCheckDisplayDelay() -> Bool {
        if let displayDelayDateString = self.displayDelayDate {
            if displayDelayDateString.isEmpty {
                return true
            }
            
            if let displayDelayDate = CommonUtil.stringToDate(displayDelayDateString) {
                // 현재 시간 가져오기
                let currentDate = Date()
                if currentDate > displayDelayDate {
                    return true
                }
            }
        }
        
        return false
    }
    
    public func isShowCheckDisplayShow() -> Bool {
        if let displayShowDateString = self.displayShowDate {
            if displayShowDateString.isEmpty {
                return true
            }
            
            if let displayShowDate = CommonUtil.stringToDate(displayShowDateString) {
                // 현재 시간 가져오기
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                // Calendar를 사용하여 두 날짜의 연도, 월, 일을 비교
                let calendar = Calendar.current
                let currentComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                let targetComponents = calendar.dateComponents([.year, .month, .day], from: displayShowDate)
                
                if currentComponents.year == targetComponents.year &&
                   currentComponents.month == targetComponents.month &&
                   currentComponents.day == targetComponents.day {
                    print("The target date is today.")
                    self.displayShowDate = ""
                    return true
                } else if displayShowDate < currentDate {
                    print("The target date has passed.")
                    self.displayShowDate = ""
                    return true
                } else {
                    print("The target date is in the future.")
                    return false
                }
            }
        }
        return false
    }
}

@available(iOS 13.0.0, *)
extension WebPopupViewController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
        let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "확인", style: .cancel) { _ in
//            completionHandler()
        }
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // confirm() 적용
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        }
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
