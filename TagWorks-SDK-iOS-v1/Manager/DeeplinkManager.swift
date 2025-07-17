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
    public var isDeferredDeeplinkInstalled: Bool = false
    public var isFirstInstall: Bool = false
    
    
    // 딥링크 애트리뷰트 정보
    var refChannelId: String = ""
    var deeplinkId: String = ""
    var campaignId: String = ""
    
    // Objective-C에서 사용할 수 있도록 콜백을 직접 타입으로 선언
//    @objc public func setCallback(_ callback: @escaping @convention(block) (Bool, URL) -> Void) {
//        self.deeplinkCallback = callback
//    }
    
    // 앱 최초 실행 여부 판단
    // UserDefault에서 false로 넘어오면 최초 실행, true로 넘어 오면 최초 실행 아님..
    var isAppFirstLaunch: Bool {
        get {
            guard let tagworksBase = TagWorks.sharedInstance.tagWorksBase else { return false }
            if tagworksBase.isAppFirstLaunch == false {
                return true
            }
            return false
        }
        set {
            guard var tagworksBase = TagWorks.sharedInstance.tagWorksBase else { return }
            tagworksBase.isAppFirstLaunch = newValue
        }
    }
    
    // 앱 진입 시 호출 (딥링크나 푸시 정보를 전달 받음)
    internal func receiveLaunchParams(url: URL?, userInfo: [AnyHashable: Any]?) {
        // url과 userInfo가 없다면 앱이 정상 실행이라 판단하고 아무 동작 안함
//        guard let launchUrl = url, let launchUserInfo = userInfo else { return }
        if url == nil && userInfo == nil { return }
        
        // 파라미터 정보를 저장하기 위함.
        let params = LaunchParams(url: url, userInfo: userInfo)

        if let callback = self.deeplinkCallback {
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
            
//            handler(params.url!.absoluteString)
            self.pendingParams = nil
        }
    }
    
//    // 앱 설치 후 최초 실행 여부 판단 후 딥링크 정보를 수신
//    internal func checkAppFirstLaunch() {
//        // SDK Initialize가 되지 않았다 판단해 아무 동작하지 않음
//        guard let _ = TagWorks.sharedInstance.tagWorksBase else { return }
//        
//        if isAppFirstLaunch == false {
//            // 앱 설치 후 최초 실행
//            // 1. App 핑거프린터 생성
//            fingerprintManager.getScriptFingerprint() { result in
//                print("🎉 모든 정보 수집 완료: \(result)")
//                
//            }
//            // 2. API 통신 후 딥링크 정보 전달 받음
//            
//            // 3. 딥링크 정보 파싱 후 로그 수집 서버로 전송
//            
//            // 4. 앱 내 랜딩페이지를 콜백으로 넘겨주고 앱 최초 실행 여부 변경 후 종료
//            
//            // isAppFirstLaunch = true
//        }
//    }
    
}

///
/// DeepLink 처리
///
extension DeeplinkManager {
    
    func handleDeeplink(_ url: URL, isDeferredDeeplink: Bool = false) {
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] 🔗 받은 딥링크 URL: \(url)")
        isDeeplinkOpened = true
        
        // URL을 Component별로 분리
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        // 예시: myapp://product?id=1234 or myapp://id=1234
        // host가 없는 경우는??
        let deeplinkScheme = components.scheme ?? ""
        let deeplinkHost = components.host ?? ""
        let deeplinkPath = components.path
        var deeplinkLandingParam = ""
        
        let queryItems = components.queryItems ?? []
        
        // "oz_landing" - 앱내 상세페이지 이동 시 필요한 파라미터
        if let landingParam = queryItems.first(where: { $0.name == "oz_landing"})?.value {
            if landingParam != "none" {
                deeplinkLandingParam = landingParam
            } else {
                deeplinkLandingParam = ""
            }
        } else {
            deeplinkLandingParam = ""
        }
        
        // "oz_ref_channel" - Referrer 정보
        if let channelId = queryItems.first(where: { $0.name == "oz_ref_channel"})?.value {
            self.refChannelId = channelId
        } else {
            self.refChannelId = ""
        }
        
        // "oz_dk_id" - Deeplink ID 정보
        if let deeplinkId = queryItems.first(where: { $0.name == "oz_dlk_id"})?.value {
            self.deeplinkId = deeplinkId
        } else {
            self.deeplinkId = ""
        }
        
        // "oz_camp_id" - Campaign ID 정보
        if let campId = queryItems.first(where: { $0.name == "oz_camp_id"})?.value {
            self.campaignId = campId
        } else {
            self.campaignId = ""
        }

        // 로그 수집 서버로 정보 전달
        // 딥링크 오픈 여부(oz_dk_click), oz_device_id(디바이스ID): SSAID와 같은 단말 ID, oz_dk_id(딥링크 ID), oz_camp_id(캠페인 ID), oz_ref_channel(유입채널 ID),
        // Driven 연동 시 - oz_medium(광고 유형 ID), oz_term(검색 광고 시 검색 키워드), oz_content(A/B 테스트 등을 위한 광고 소재 식별자)
        
        // 콜백을 통해 스키마 정보 전달
        routeToDeeplinkLanding(scheme: deeplinkScheme, host: deeplinkHost, path: deeplinkPath, landingParam: deeplinkLandingParam)
        
        // 서버에 수집 로그 전달
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] isFirstInstall: \(isFirstInstall), isDeeplinkOpened: \(isDeeplinkOpened)")
    }
    
    private func routeToDeeplinkLanding(scheme: String, host: String, path: String, landingParam: String) {
        // 여기에 라우팅 로직 넣으세요
//        print("🔗 Landing 페이지 이동: \(landing)")
        let schemeUrl = "\(scheme)://\(host)\(path)?\(landingParam)"
        print("🔗 콜백 전달 URL: \(schemeUrl)")
        
        if let deeplinkCallback = self.deeplinkCallback {
            if self.deeplinkId.isEmpty {
                deeplinkCallback(false, URL(string: schemeUrl)!)
            } else {
                deeplinkCallback(true, URL(string: schemeUrl)!)
            }
            self.schemeURL = ""
        } else {
            self.schemeURL = schemeUrl
        }
    }
}


///
/// Push 처리
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
