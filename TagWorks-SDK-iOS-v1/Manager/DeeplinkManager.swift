//
//  DeeplinkManager.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 7/1/25.
//

import Foundation

@objc public class DeeplinkManager: NSObject {
    
    @objc public static let sharedInstance = DeeplinkManager()
    
    override private init() {}
    
    // 딥링크나 Push를 통해서 앱이 실행됐을 때 파라미터로 넘어온 값을 저장할 구조체
    struct LaunchParams {
        let url: URL?
        let userInfo: [AnyHashable: Any]?
    }
    
    private let fingerprintManager = FingerprintManager()
    
    private var pendingParams: LaunchParams?
    private var schemeURL: String?
    
    // 딥링크 콜백 타입 정의 (isFromMySDK: Bool, url: URL)
//    typealias DeeplinkCallback = (_ isTagworksDeeplink: Bool, _ url: URL) -> Void
    
    
    // 직접 block 타입 정의 (typealias 없이)
    private var deeplinkCallback: (@convention(block) (Bool, URL) -> Void)?
    
//    // Objective-C에서 사용 가능한 콜백 정의 (NSObject 기반 + @escaping 불가 → 보관만 가능)
//    private var callback: ((Bool, URL) -> Void)?
//    private var deeplinkCallback: DeeplinkCallback?
    
    
    
    // 딥링크 정보
    public var isDeeplinkOpened: Bool = false
    public var isDeferredDeeplinkOpened: Bool = false
//    public var isDeferredDeeplinkInstalled: Bool = false
    public var isFirstInstall: Bool = false
    public var isReinstall: Bool = false
    
    // 딥링크 애트리뷰트 정보
    var refChannelId: String?
    var deeplinkId: String?
    var campaignId: String?
    var landingPageURL: String?
    
    // Objective-C에서 사용할 수 있도록 콜백을 직접 타입으로 선언
//    @objc public func setCallback(_ callback: @escaping @convention(block) (Bool, URL) -> Void) {
//        self.deeplinkCallback = callback
//    }
    
    // 앱 최초 실행 여부 판단
    // UserDefault에서 false로 넘어오면 최초 실행, true로 넘어 오면 최초 실행 아님..
    var isAppFirstLaunched: Bool {
        get {
            guard let tagworksBase = TagWorks.sharedInstance.tagWorksBase else { return false }
            if tagworksBase.isAppFirstLaunched == false {
                return true
            }
            return false
        }
        set {
            guard var tagworksBase = TagWorks.sharedInstance.tagWorksBase else { return }
            tagworksBase.isAppFirstLaunched = newValue
        }
    }
    
    // 앱 진입 시 호출 (딥링크나 푸시 정보를 전달 받음)
    internal func receiveLaunchParams(url: URL?, userInfo: [AnyHashable: Any]?) {
        // url과 userInfo가 없다면 앱이 정상 실행이라 판단하고 아무 동작 안함
        if url == nil && userInfo == nil { return }
        
        // 파라미터 정보를 저장하기 위함.
        let params = LaunchParams(url: url, userInfo: userInfo)

        if self.deeplinkCallback != nil {
            // 콜백이 등록되어 있는 경우, 랜딩 페이지 정보를 전달

            // 딥링크 정보 처리
            if let deeplinkUrl = url {
                // 딥링크로 실행이 된 경우,
                handleDeeplink(deeplinkUrl)
            }
            
            // 푸시 정보 처리
            if let pushUserInfo = userInfo {
                // Push로 실행이 된 경우,
                handlePush(pushUserInfo)
            }
            
//            self.deeplinkCallback = nil
        } else {
            // 아직 콜백이 등록되지 않은 경우 보관
            self.pendingParams = params
        }
    }

    // 앱 준비 완료 후 콜백 등록
    internal func registerDeeplinkCallback(_ callback: @escaping @convention(block) (Bool, URL) -> Void) {
        
        // 콜백을 먼저 등록한 경우, 콜백을 저장
        self.deeplinkCallback = callback
        
        if let params = self.pendingParams {
            // 보관된 파라미터가 있는 경우, 바로 콜백을 통해 전달
            // 딥링크 정보 처리
            if let deeplinkUrl = params.url {
                // 딥링크로 실행이 된 경우,
                handleDeeplink(deeplinkUrl)
            }
            
            // 푸시 정보 처리
            if let pushUserInfo = params.userInfo {
                // Push로 실행이 된 경우,
                handlePush(pushUserInfo)
            }
            
            self.pendingParams = nil
        }
    }
}

///
/// DeepLink 처리
///
extension DeeplinkManager {
    
    /// 딥링크 정보 저장 변수값들 초기화
    func initailizeDeeplinkInfo() {
        self.landingPageURL = nil
        self.refChannelId = nil
        self.deeplinkId = nil
        self.campaignId = nil
    }
    
    /// 딥링크 URL을 파싱하여 메모리 로드
    /// 리턴값 : TagManager의 딥링크 여부 (oz_dlk_id 가 존재하는지 여부)
    // 예) obzenapp://prod/20054?oz_landing=key1%3Dvlaue1&oz_dlk_id=dlk1646856&oz_ref_channel=TG1128092&oz_camp_id=0
    func parserDeeplinkUrl(_ url: URL) -> Bool {
        TagWorks.log("🔗 파싱할 딥링크 URL: \(url.absoluteString)")
//        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] 🔗 파싱할 딥링크 URL: \(url.absoluteString)")
        
        // URL을 Component별로 분리
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        
        let deeplinkScheme = components.scheme ?? ""
        let deeplinkHost = components.host ?? ""
        let deeplinkPath = components.path
        
        let queryItems = components.queryItems ?? []
        
        // "oz_landing" - 앱내 상세페이지 이동 시 필요한 파라미터
        let landingParam = queryItems.first(where: { $0.name == "oz_landing" })?.value
        let deeplinkLandingParam = (landingParam != "none") ? (landingParam ?? "") : ""
        
        if deeplinkLandingParam.isEmpty {
            self.landingPageURL = "\(deeplinkScheme)://\(deeplinkHost)\(deeplinkPath)"
        } else {
            self.landingPageURL = "\(deeplinkScheme)://\(deeplinkHost)\(deeplinkPath)?\(deeplinkLandingParam)"
        }
        
        // "oz_ref_channel" - Referrer 정보
        self.refChannelId = queryItems.first(where: { $0.name == "oz_ref_channel" })?.value ?? ""
        
        // "oz_dk_id" - Deeplink ID 정보
        self.deeplinkId = queryItems.first(where: { $0.name == "oz_dlk_id" })?.value ?? ""
        
        // "oz_camp_id" - Campaign ID 정보
        self.campaignId = queryItems.first(where: { $0.name == "oz_camp_id" })?.value ?? ""
        
        TagWorks.log("🔗 딥링크 URL 파싱 정보: \(self.landingPageURL ?? ""), \(self.refChannelId ?? ""), \(self.deeplinkId ?? ""), \(self.campaignId ?? "")")
//        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] 🔗 딥링크 URL 파싱 정보: \(self.landingPageURL ?? ""), \(self.refChannelId ?? ""), \(self.deeplinkId ?? ""), \(self.campaignId ?? "")")
        
        if self.deeplinkId != nil && self.deeplinkId!.isEmpty == false {
            return true
        }
        
        return false
    }
    
    /// 디퍼드 딥링크 정보 조회
    func checkDeferredDeeplink(_ completion: @escaping (Bool) -> Void) {
        
        // 재설치 여부 판단
        if isFirstInstall == false {
            isReinstall = true
        }
        
        // 디바이스 FingerPrint 수집
        fingerprintManager.getScriptFingerprint() { result in
            print("🎉 모든 정보 수집 완료: \(result)")
            
            //            let fingerprint = result as FingerprintManager.FingerprintResult
            //            let screenResolution = DeviceInfo.getDeviceScreenResolution()
            //            print("🌽 : " + result.userAgent! + "|" + CommonUtil.getCurrentTimeZone() + "|" + Locale.httpAcceptLanguage + "|" + CommonUtil.getIPAddressForCurrentInterface()! + "|" + "\(screenResolution.width),\(screenResolution.height)")
            
            // 앱 처음 실행 디퍼드 딥링크 Rest API 호출
            let restApiManager = RestApiManager()
            var isDeferredDeeplink = false
            var deeplinkInfo: String = ""
            
            let siteId = TagWorks.sharedInstance.siteId ?? ""
            var cntn_id = ""
            let components = siteId.split(separator: ",")
            // 키와 값 추출
            if components.count > 0 {
                cntn_id = String(components[1])
            }
            // MARK: 파라미터 정보에 앱 실행 시간은 Rest API 호출하는 시간으로 API에서 처리..
            restApiManager.requestDeferredDeeplinkInfo(fp_basic: result.requiredHash ?? "",
                                                       fp_canvas: result.canvasHash ?? "",
                                                       fp_webgl: result.webGLHash ?? "",
                                                       fp_audio: result.audioHash ?? "",
                                                       cntn_id: cntn_id) { success, resultData in
                print(resultData)
                if let resultDict = resultData as? [String: String] {
                    // let isReinstallResult = resultDict["is_reinstall"]!     // 해당 값은 AOS에서만 서버 체크 후 사용하는 값임.
                    let deeplinkInfoResult = resultDict["oz_deeplink"]!
                    
                    if deeplinkInfoResult.isEmpty == false {
                        // 디퍼드 딥링크 정보 있음
                        isDeferredDeeplink = true
                        deeplinkInfo = deeplinkInfoResult
                    } else {
                        // 디퍼드 딥링크 정보 없음
//                        isDeferredDeeplink = false
//                        deeplinkInfo = ""
                        
                        self.initailizeDeeplinkInfo()
                        completion(false)
                    }
                }
                
                if isDeferredDeeplink == true {
                    // 디퍼드 딥링크 정보 존재할 때
                    self.isDeferredDeeplinkOpened = true
                    self.isDeeplinkOpened = true
                    
                    // 딥링크 정보 URL을 파싱
                    if self.parserDeeplinkUrl(URL(string: deeplinkInfo)!) == true {
                        
                        // 서버에 딥링크 정보 로그 전송
                        self.logEventDeeplinkInfo()
                    }
                    
                    // 앱으로 랜딩페이지 정보 라우팅
                    self.routeToDeeplinkLanding()
                    
                    // 딥링크 정보 초기화
                    self.initailizeDeeplinkInfo()
                }
            }
        }
    }
    
    
    /// 딥링크 실행 시 처리..
    func handleDeeplink(_ url: URL, isDeferredDeeplink: Bool = false) {
        TagWorks.log("🔗 받은 딥링크 URL: \(url)")
//        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] 🔗 받은 딥링크 URL: \(url)")
        isDeferredDeeplinkOpened = false
        isDeeplinkOpened = true
        
        if parserDeeplinkUrl(url) == true {
            // 로그 수집 서버로 정보 전달
            logEventDeeplinkInfo()
        }

        // 콜백을 통해 스키마 정보 전달
        routeToDeeplinkLanding()
        
        // 딥링크 정보 초기화
        initailizeDeeplinkInfo()
    }
    
    // 딥링크 정보를 로그 수집 서버에 전송
    func logEventDeeplinkInfo() {

        // 로그 수집 서버로 정보 전달
        // 딥링크 오픈 여부(oz_dk_click), oz_device_id(디바이스ID): SSAID와 같은 단말 ID, oz_dk_id(딥링크 ID), oz_camp_id(캠페인 ID), oz_ref_channel(유입채널 ID),
        // Driven 연동 시 - oz_medium(광고 유형 ID), oz_term(검색 광고 시 검색 키워드), oz_content(A/B 테스트 등을 위한 광고 소재 식별자)
        
        let event = Event(tagWorks: TagWorks.sharedInstance,
                          eventType: StandardEventTag.DEEPLINK,
                          isDeepLink: self.isDeeplinkOpened == true ? "1" : "0",
                          isDeferredDeepLink: isDeferredDeeplinkOpened == true ? "1" : "0",
                          deeplinkId: self.deeplinkId,
                          isFirstInstall: self.isFirstInstall == true ? "1" : "0",
                          isReinstall: self.isReinstall == true ? "1" : "0",
                          campaignId: self.campaignId,
                          refChannel: self.refChannelId,
                          landingPageUrl: self.landingPageURL?.urlEncodedForQueryWithEqual
        )
        TagWorks.sharedInstance.addQueueOrDispatch(event)
    }
    
    private func routeToDeeplinkLanding() {
        // 여기에 라우팅 로직 넣으세요
//        print("🔗 Landing 페이지 이동: \(landing)")
//        let schemeUrl = "\(scheme)://\(host)\(path)?\(landingParam)"
        let landingUrl = self.landingPageURL ?? ""
        
        print("🔗[TagWorks v\(CommonUtil.getSDKVersion()!)] App에 전달할 랜딩페이지 URL: \(landingUrl)")
        
        if let deeplinkCallback = self.deeplinkCallback {
            if self.deeplinkId != nil && self.deeplinkId!.isEmpty == false {
                deeplinkCallback(true, URL(string: landingUrl)!)
            } else {
                deeplinkCallback(false, URL(string: landingUrl)!)
            }
            self.schemeURL = ""
        } else {
            self.schemeURL = landingUrl
        }
    }
}


///
/// Push 처리 (추후 개발)
///
extension DeeplinkManager {
    
    func handlePush(_ userInfo: [AnyHashable: Any]) {
        print("📦 받은 Push userInfo: \(userInfo)")
        
        // 1. landing 파라미터 기반 처리
        if let landing = userInfo["landing"] as? String {
            print("🔗 푸시 → landing: \(landing)")
            routeToLanding(landing)
            return
        }

        // 2. action 파라미터 기반 처리
        if let action = userInfo["action"] as? String {
            print("🛠 푸시 → action: \(action)")
            performAction(action)
            return
        }
        
        print("❓ 처리할 수 없는 푸시 내용")
    }
    
    private func routeToLanding(_ landing: String) {
        // 실제 라우팅 로직 구현
        print("➡️ 이동할 landing 페이지: \(landing)")
    }

    private func performAction(_ action: String) {
        // 예: "refresh", "logout", "navigate:product?id=1234" 등
        print("✅ 실행할 액션: \(action)")
    }
}
