//
//  TagWorks.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import UIKit
import Foundation
import AdSupport
import AppTrackingTransparency

/// TagWorks 클래스는 SDK 모듈내에서 가장 최상위에 존재하는 클래스입니다.
@objc final public class TagWorks: NSObject {
    
    // MARK: - 싱글톤 객체 생성 및 반환
    @objc static public let sharedInstance = TagWorks()
    
    private override init() {
        super.init()
    }
    
    // MARK: - 클래스 내부 변수
    
    /// Logger 객체입니다.
    @objc public var logger: Logger = DefaultLogger(minLevel: .warning)
    
    /// UserDefault 객체입니다.
    internal var tagWorksBase: TagWorksBase?
    
    /// 수집된 로그를 발송전 보관하는 컬렉션입니다.
    private var queue: DefaultQueue?
    
    /// 수집된 로그를 발송하는 객체입니다.
    private var dispatcher: DefaultDispatcher?
    private var retryCount = 0
    
    //-----------------------------------------
    // 필수 설정값
    
    /// 수집대상이 되는 컨테이너 식별자를 지정합니다.
    /// - 해당 사이트(고객사) 별로 수동으로 발급되는 식별자입니다. 차후 API를 통해 자동발급 되어야 할 필요가 있음. (사이트에서 전달받음)
    /// - Requires: TagManager 에서 발급된 컨테이너 ID를 입력합니다.
    /// - Important: siteId는 "[0-9],[0-9a-zA-Z]" 와 같은 형식을 가집니다.
    internal var siteId: String?
    
    /// 수집되는 사용자의 방문자 식별자입니다.
    /// 현재 유효한 사용자의 방문자 식별자를 반환합니다.
    /// * 최초로 수집되어 방문자 식별자가 없는 경우 신규 ID를 발급합니다.
    /// * 생성된 방문자 식별자는 UUID를 기반으로 하며 소문자로 발급됩니다.
    /// - 해당 디바이스의 고유 식별자입니다. (UUID를 사용하나 바뀌지 않는것이 좋음)
    @objc public var visitorId: String {
        get {
            if let existingId = tagWorksBase?.visitorId {
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] exist visitorId : \(existingId)")
//                UIPasteboard.general.string = existingId
                return existingId
            }
            let id = UUID().uuidString.lowercased()
            tagWorksBase?.visitorId = id
            print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] new visitorId : \(id)")
            return id
        }
        set {
            tagWorksBase?.visitorId = newValue
        }
    }
    
    /// 수집되는 사용자의 유저 식별자 (고객 식별자)입니다.
    ///  - 로그인되어 사용하는 사용자의 유저 식별자입니다. (사이트에서 전달받음)
    @objc public var userId: String?
//    @objc public var userId: String? {
//        get {
//            return tagWorksBase?.userId
//        }
//        set {
//            tagWorksBase?.userId = newValue
//        }
//    }
    
    /// 수집 허용 여부 입니다.
    @objc public var isOptedOut: Bool {
        get {
            guard let base = tagWorksBase else { return false }
            return base.optOut
        }
        set {
            tagWorksBase?.optOut = newValue
        }
    }
    
    /// 수집되는 사용자의 App Version입니다.
    /// - 값이 없을 경우에는 내부적으로 Short Version을 사용합니다.
    @objc public var appVersion: String?
    
    /// 수집되는 사용자의 App 이름입니다.
    /// - 값이 없을 경우에는 내부적으로 Display Bundle Name을 사용합니다.
    @objc public var appName: String?
    
    /// 수집되는 사용자 Device의 IDFA(광고식별자)
    @objc public var isEnabledAdId: Bool = false

//    @objc public var adId: String = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    @objc public var adId: String?
    
    // iOS의 광고식별자를 받아옵니다.
    @objc public func setAdid(_ uuid: String) {
        self.adId = uuid
    }
    
    // 필수 설정값 end
    //-----------------------------------------
    
    /// 공통으로 저장되는 디멘전 컬렉션입니다.
    /// * 해당 컬렉션에 저장된 디멘전은 모든 이벤트 호출시 자동으로 들어갑니다.
    /// * 이벤트 호출시 디멘전을 별도로 추가 한 경우 우선적으로 나중에 호출된 디멘전이 저장됩니다.
    internal var dimensions: [Dimension] = []
    
    /// 수집되는 어플리케이션의 기본 Url 주소입니다.
    /// * 수집대상이 되는 어플리케이션의 bundleIdentifier 주소를 기본으로 하며, 별도 지정시 지정된 값으로 수집됩니다.
    @objc var contentUrl: URL?
    
    /// 수집되는 어플리케이션의 현재 Url 주소입니다.
    /// * PageView 이벤트 호출시 contentUrl + 지정된 Url 경로 순으로 수집됩니다.
    @objc public var currentContentUrlPath: URL?
    
    /// 한번에 발송할 수 있는 이벤트 구조체의 수입니다.
    private let numberOfEventsDispatchedAtOnce = 20
    
    /// 현재 이벤트 로그 발송중 여부입니다.
    private(set) var isDispatching = false
    
    /// 이벤트 발송 주기 사용 여부입니다.
    /// false로 셋팅한 경우, 이벤트 즉시 발송
    /// true로 셋팅한 경우, 타이머를 이용한 발송
    @objc var isUseIntervals = false
    
    /// 이벤트 로그의 발송 주기 입니다. (단위 : 초)
    /// * 발송 주기의 기본값은 10 입니다.
    /// * 값을 0으로 지정하는 경우 이벤트 수집 즉시 발송됩니다.
    /// * 값을 0이하로 지정하는 경우 이벤트 로그 발송을 자동으로 수행하지 않습니다.
    ///     - dispatch() 함수를 이용하여 수동으로 발송해야 합니다.
    @objc private var dispatchInterval: TimeInterval = 5.0
    
    /// SDK 디버깅을 위한 로그 출력 플래그
    /// 디폴트는 출력을 하지 않으나, 이슈 발생 시 true로 셋팅 하여 디버깅 로그를 통해 SDK 플로우를 디버깅
    @objc public var isDebugLogPrint: Bool = false
    @objc public var isDebugLogPost: Bool = false
    
    @objc public var isManualDispatch: Bool = false
    
    @objc public var isUseDynamicParameter: Bool = false
    
    @objc private var userAgent: String? {
        get {
            return self.dispatcher?.userAgent
        }
        set {
            self.dispatcher?.userAgent = newValue
        }
    }
    
    // 주기 발송을 하기 위한 타이머
    private var dispatchTimer: Timer?
    
    /// 웹뷰로부터 자바스크립트로 웹뷰 이벤트를 전달받아 처리하는 클래스 객체
    @objc public let webViewInterface: WebInterface = WebInterface()
    
    // 수집 서버로 전송 실패 시 재전송 여부 설정 (true 설정 시 3번의 Retry 진행)
    @objc public var isDispatchRetry = false
    
    /// Interval을 사용할 경우, 앱이 예기치 않은 종료로 인해 큐에 이벤트가 남아있을 때 앱 시작 시 발송하지 못한 이벤트를 전송 - by Kevin. 2025.04.28
    @objc public var localQueueEnabled: Bool = false
    
    /// 앱이 비정상 종료 시 인터페이스를 통해 에러 로그를 저장 및 앱 재실행 시 에러 로그 전송 - by Kevin. 2025.05.12
    @objc public var errorReportEnabled: Bool = true
    
    // 화면 전환 시 자동 감지 로그 수집 여부 (스위즐링 감시 여부)
    @objc public var autoTrackingPage: Bool = true
    @objc public var autoTrackingButtonClick: Bool = false
    @objc public var autoTrackingApplication: Bool = true
    @objc public var autoTrackingScene: Bool = true
    
    // 화면 전환 자동 수집 시 수집하길 원하지 않는 ViewController들을 저장하는 변수
    private var excludedPages: [String] = []
    
    // UIButton의 객체를 등록하여 태깅을 하기 위한 변수
    // 객체를 weak로 참조하기에 메모리 릭 발생 위험 없음.
    private var registeredTagButtons: NSHashTable<UIButton> = NSHashTable.weakObjects()
    
    private let fingerprintManager = FingerprintManager()
    
    // MARK: - 클래스 객체 함수
    
    // MARK: InstanceConfig (초기 버전부터 버전별 Config 사용)
    
    /// 이벤트 전송에 필요한 필수 항목 입력
    /// - Parameters:
    ///   - siteId: 수집 대상이 되는 사이트(고객사) 식별자
    ///   - baseUrl: 수집 로그 발송을 위한 서버 URL
    ///   - userAgent: 수집 대상의 userAgent 객체 String
    @objc public func setInstanceConfig(siteId: String,
                                        baseUrl: URL,
                                        isUseIntervals: Bool,
                                        dispatchInterval: TimeInterval = 3.0,
                                        userAgent: String? = nil,
                                        appVersion: String? = nil,
                                        appName: String? = nil) {
        
        setInstanceConfig(siteId: siteId,
                          baseUrl: baseUrl,
                          isUseIntervals: isUseIntervals,
                          dispatchIntervalWithSeconds: dispatchInterval,
                          sessionTimeOutWithSeconds: 5.0,
                          isManualDispatch: false,
                          appVersion: appVersion,
                          appName: appName,
                          isUseDynamicParameter: false,
                          isEnabledAdId: false)
    }
    
    /// 이벤트 전송에 필요한 필수 항목 입력
    ///  1.1.10 버전 이후 추가 - 파라미터에 sesstionTimeOut 값 추가
    /// - Parameters:
    ///   - siteId: 수집 대상이 되는 사이트(고객사) 식별자
    ///   - baseUrl: 수집 로그 발송을 위한 서버 URL
    ///   - userAgent: 수집 대상의 userAgent 객체 String
    @objc public func setInstanceConfig(siteId: String,
                                        baseUrl: URL,
                                        isUseIntervals: Bool,
                                        dispatchInterval: TimeInterval = 3.0,
                                        sessionTimeOut: TimeInterval = 5.0,
                                        userAgent: String? = nil,
                                        appVersion: String? = nil,
                                        appName: String? = nil) {
        
        setInstanceConfig(siteId: siteId,
                          baseUrl: baseUrl,
                          isUseIntervals: isUseIntervals,
                          dispatchIntervalWithSeconds: dispatchInterval,
                          sessionTimeOutWithSeconds: sessionTimeOut,
                          isManualDispatch: false,
                          appVersion: appVersion,
                          appName: appName,
                          isUseDynamicParameter: false,
                          isEnabledAdId: false)
    }
    
    /// 이벤트 전송에 필요한 필수 항목 입력
    ///  1.1.22 버전 이후 추가 - 파라미터에 isUseDynamicParameter 값 추가
    /// - Parameters:
    ///   - siteId: 수집 대상이 되는 사이트(고객사) 식별자
    ///   - baseUrl: 수집 로그 발송을 위한 서버 URL
    ///   - userAgent: 수집 대상의 userAgent 객체 String
    @objc public func setInstanceConfig(siteId: String,
                                        baseUrl: URL,
                                        isUseIntervals: Bool,
                                        dispatchInterval: TimeInterval = 3.0,
                                        sessionTimeOut: TimeInterval = 5.0,
                                        userAgent: String? = nil,
                                        isManualDispatch: Bool = false,
                                        appVersion: String? = nil,
                                        appName: String? = nil,
                                        isUseDynamicParameter: Bool = true,
                                        isEnabledAdId: Bool = false) {
        
        setInstanceConfig(siteId: siteId,
                          baseUrl: baseUrl,
                          isUseIntervals: isUseIntervals,
                          dispatchIntervalWithSeconds: dispatchInterval,
                          sessionTimeOutWithSeconds: sessionTimeOut,
                          isManualDispatch: isManualDispatch,
                          appVersion: appVersion,
                          appName: appName,
                          isUseDynamicParameter: isUseDynamicParameter,
                          isEnabledAdId: isEnabledAdId)
    }
    
    /// 이벤트 전송에 필요한 필수 항목 입력
    /// - Parameters:
    ///   - siteId: 수집 대상이 되는 사이트(고객사) 식별자
    ///   - baseUrl: 수집 로그 발송을 위한 서버 URL
    ///   - userAgent: 수집 대상의 userAgent 객체 String
    @objc public func setInstanceConfig(siteId: String,
                                        baseUrl: URL,
                                        isUseIntervals: Bool,
                                        dispatchIntervalWithSeconds: TimeInterval = 3.0,
                                        sessionTimeOutWithSeconds: TimeInterval = 5.0,
                                        userAgent: String? = nil,
                                        isManualDispatch: Bool = false,
                                        appVersion: String? = nil,
                                        appName: String? = nil,
                                        isUseDynamicParameter: Bool = true,
                                        isEnabledAdId: Bool = false) {
        
        setInstanceConfig(siteId: siteId,
                          baseUrl: baseUrl,
                          isUseIntervals: isUseIntervals,
                          dispatchIntervalWithSeconds: dispatchIntervalWithSeconds,
                          sessionTimeOutWithSeconds: sessionTimeOutWithSeconds,
                          isManualDispatch: isManualDispatch,
                          appVersion: appVersion,
                          appName: appName,
                          isUseDynamicParameter: isUseDynamicParameter,
                          isEnabledAdId: isEnabledAdId)
    }
    
    /// 이벤트 전송에 필요한 필수 항목 입력
    ///  1.1.28 버전 이후 제거 - 파라미터에 userAgent 값 제거
    ///  isUseDynamicParameter 디폴트 값을 true로 설정
    /// - Parameters:
    ///   - siteId: 수집 대상이 되는 사이트(고객사) 식별자
    ///   - baseUrl: 수집 로그 발송을 위한 서버 URL
    ///   - userAgent: 수집 대상의 userAgent 객체 String
    @objc public func setInstanceConfig(siteId: String,
                                        baseUrl: URL,
                                        isUseIntervals: Bool,
                                        dispatchIntervalWithSeconds: TimeInterval = 3.0,
                                        sessionTimeOutWithSeconds: TimeInterval = 5.0,
                                        isManualDispatch: Bool = false,
                                        appVersion: String? = nil,
                                        appName: String? = nil,
                                        isUseDynamicParameter: Bool = true,
                                        isEnabledAdId: Bool = false) {
        self.siteId = siteId
        self.isUseIntervals = isUseIntervals
        self.isManualDispatch = isManualDispatch
        var interval = dispatchIntervalWithSeconds
        if interval <= 1 {
            interval = 1
        } else if interval >= 10 {
            interval = 10
        }
        self.dispatchInterval = interval
        self.queue = DefaultQueue()
//        self.dispatcher = DefaultDispatcher(serializer: EventSerializer(), timeOut: sessionTimeOutWithSeconds, baseUrl: baseUrl, userAgent: userAgent)
        self.dispatcher = DefaultDispatcher(serializer: EventSerializer(), timeOut: sessionTimeOutWithSeconds, baseUrl: baseUrl, userAgent: nil)
        self.appVersion = appVersion
        self.appName = appName
        self.isUseDynamicParameter = isUseDynamicParameter
        self.tagWorksBase = TagWorksBase(suitName: "\(siteId)\(baseUrl.absoluteString)")
        self.contentUrl = URL(string: "APP://\(AppInfo.getApplicationInfo().bundleIdentifier ?? "")/")
        self.isEnabledAdId = isEnabledAdId
        
        self.webViewInterface.delegate = self
        
        // 앱 크래쉬 자동 탐지
        CrashLogManager.sharedInstance.setupGlobalSignalHandler()
        
        // 광고 식별자 사용 여부 설정에 따라 자동으로 광고 식별자 가져옴
        if isEnabledAdId {
            requestIDFA() { idfa in
                self.adId = idfa
            }
        }
        
        // 로컬큐에 이벤트 스트링이 존재할 때 서버 전송
        let _ = sendLocalQueueEvent()
        
        // UserDefalut에 저장된 에러 로그 서버 발송
        sendErrorReport()
        sendCrashReport()
        
        // 스위즐링
        SwizzlingManager.sharedInstance.lifecycleTracking()
        
        // 디퍼드 딥링크 체크 - 추후 개방
//        DispatchQueue.main.async {
//            self.checkIsAppFirstLaunch()
//        }
    }
    
    @objc public func setManualDispatch(_ isManual: Bool) {
        self.isManualDispatch = isManual
    }
    
    // userId 초기화 함수 - 명시적인 호출을 통해 userId 초기화
    @objc public func clearUserId() {
        userId = nil
    }
    
    // MARK: 화면 전환 자동 수집 시 예외 클래스 처리 (클래스명을 Array로 저장)
    @objc public func excludeAutoTrackingPages(_ pageClasses: [AnyClass]) {
        excludedPages = pageClasses.map { String(describing: $0) }
    }
    
    internal func isContainsExcludedPage(_ vcName: String) -> Bool {
        return excludedPages.contains(vcName)
    }
    
    // MARK: 버튼 객체를 넘겨 받아 해당 버튼들에 대해서만 스위즐링을 통해 자동 이벤트 발생 처리
    @objc public func registerButtons(_ buttons: [UIButton]) {
        for button in buttons {
            registeredTagButtons.add(button)
        }
    }
    
    public func removeAllRegisterButtons() {
        registeredTagButtons.removeAllObjects()
    }

    internal func isRegistered(_ button: UIButton) -> Bool {
        return registeredTagButtons.contains(button)
    }
    
    // MARK: 광고 식별자를 권한 체크 후 가져오는 함수
    private func requestIDFA(completion: @escaping (String?) -> Void) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    completion(idfa)
                case .denied, .restricted, .notDetermined:
                    completion(nil)
                @unknown default:
                    completion(nil)
                }
            }
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                completion(idfa)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: 딥링크 관련 함수
    /// 앱 설치 시 최초 실행 여부에 따라 디퍼드 딥링크 정보 수신
    private func checkIsAppFirstLaunch() {
        // 앱이 최초 실행 시 동작
        // 1. isAppFirstLaunch == false 일 경우에만 동작
        guard tagWorksBase?.isAppFirstLaunched == false else { return }
        
        // 2. 특정 폴더 생성 시간 가져와서 3일이 지났다면 패스, 아니면 디퍼드 딥링크 Rest api 호출, 예)2025-07-01 10:06:23 UTC
        let installDate = CommonUtil.getAppInstallDateFromLibrary() ?? Date()
        let calendar = Calendar.current
        // 두 날짜 사이의 차이를 일(day) 단위로 계산 - 날짜가 바뀐 횟수를 기준으로 차이를 구하기 때문에 비교 기준값에 -1을 해줘야 함 (예: 07-01, 07-10 비교 시 결과값은 8)
        if let daysBetween = calendar.dateComponents([.day], from: installDate, to: Date()).day {
            if daysBetween <= 2 {
                
                // API 통신을 통해 디퍼드 딥링크 정보 존재 여부 판별
                DeeplinkManager.sharedInstance.checkDeferredDeeplink() { result in
                    // 결과값 - result
                }
            } else {
                // 앱 설치 후 3일이 지났다고 판단..
                // 아무 행동 안하기로 결정.. 장등수 상무님 의견 반영 - By Kevin 2025.07.24
//                let isFirstInstall = DeeplinkManager.sharedInstance.isFirstInstall
//                let isDeeplinkOpened = DeeplinkManager.sharedInstance.isDeeplinkOpened
//                
//                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] isFirstInstall: \(isFirstInstall), isDeeplinkOpened: \(isDeeplinkOpened)")
            }
        }
        

        // 최초 실행 완료 플래그 셋팅
        tagWorksBase?.isAppFirstLaunched = true
    }
    
    ///
    /// 딥링크나 푸시를 통해 앱이 실행이 된 경우, 파라미터를 받아서 파싱 후 분석하여 로그 수집
    ///
    @objc public func launchWithOptions(url: URL?, userInfo: [AnyHashable: Any]?) {
        DeeplinkManager.sharedInstance.receiveLaunchParams(url: url, userInfo: userInfo)
    }
    
    ///
    /// 딥링크로 앱이 실행이 된 경우, 앱에서 등록한 콜백 함수를 통해 앱의 랜딩 페이지로 이동시킴
    ///
    @objc public func registerDeeplinkCallback(_ callback: @escaping @convention(block) (Bool, URL) -> Void) {
//    @objc public func registerDeeplinkCallback(_ callback: DeeplinkCallback) {
        DeeplinkManager.sharedInstance.registerDeeplinkCallback(callback)
    }
    
    /// 이벤트 로그 발생 주기 타이머를 시작합니다.
    private func startDispatchTimer() {
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] startDispatchTimer!!")
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self.startDispatchTimer()
            }
            return
        }
        guard dispatchInterval >= 0  else { return }
        if let dispatchTimer = dispatchTimer {
            dispatchTimer.invalidate()
            self.dispatchTimer = nil
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dispatchTimer = Timer.scheduledTimer(timeInterval: self.dispatchInterval,
                                                      target: self,
                                                      selector: #selector(self.dispatch),
                                                      userInfo: nil,
                                                      repeats: false)
        }
    }
    
    private func stopDispatchTimer() {
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] stopDispatchTimer!!")
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self.stopDispatchTimer()
            }
            return
        }
        guard let dispatchTimer = dispatchTimer else { return }
        
        dispatchTimer.invalidate()
        self.dispatchTimer = nil
    }
    
    /// ## Queue Event 추가 ##
    
    /// 수집 이벤트 호출시 생성된 이벤트 구조체를 Queue에 저장합니다.
    /// - Parameter event: 이벤트 구조체
    internal func addQueue(event: Event) {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self.addQueue(event: event)
            }
            return
        }
        guard !isOptedOut else { return }
        guard var queue = self.queue else { return }
        
        // IBK 여정분석 요청에 따라 큐 사이즈를 200개로 제한 - 2025.02.27
        // by Kevin.
        guard queue.size < 200 else { return }
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Added queue event!!")
        logger.verbose("Added queue event: \(event)")
        
        queue.enqueue(event: event) {
            if self.queue!.size >= 1 && self.dispatchTimer == nil {
                if self.isUseIntervals && !self.isManualDispatch {
                    self.startDispatchTimer()
                }
            }
        }
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Queue Size : \(queue.size)")
    }
    
    // MARK: ## 이벤트 발송 관련 함수 ##
    
    /// 현재 Queue에 저장되어 있는 이벤트 구조체를 즉시 발송합니다. (수동 처리) - 타이머 사용 안함.
    internal func dispatchAtOnce(event: Event) -> Bool {
        guard isInitialize() else {
            return false
        }
        
        guard !isOptedOut else {
            return false
        }
        
        guard let dispatcher = self.dispatcher else { return false }
        DispatchQueue.main.async {
            dispatcher.send(events: [event], success: { [weak self] in
                guard let self = self else { return }
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] dispatchAtOnce Send Success!! \n - \(event)")
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] dimension value - \(event.dimensions.map {"{\($0.key), \($0.index), \($0.value), \($0.numValue)}"})")
                self.isDispatching = false
            }, failure: { [weak self] error in
                guard let self = self else { return }
                self.isDispatching = false
                self.logger.warning("Failed dispatching events with error \(error)")
            })
        }
        return true
    }
    
    /// 현재 Queue에 저장되어 있는 이벤트 구조체를 즉시 발송합니다. (수동 처리)
    @objc public func dispatch() -> Bool {
        
        // 타이머 초기화 (재실행을 위해 필요)
        self.dispatchTimer = nil
        
        guard isInitialize() else {
            return false
        }
        
        guard !isOptedOut else {
            return false
        }
        
        guard !isDispatching else {
            print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] is already dispatching.")
            logger.verbose("is already dispatching.")
            return false
        }
        guard let queue = self.queue, queue.size > 0 else {
            print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Dispatch queue is empty.")
            logger.info("No need to dispatch. Dispatch queue is empty.")
            return false
        }
        logger.info("Start dispatching events")
        isDispatching = true
        dispatchBatch()
        return true
    }
    
    /// 현재 Queue에 저장되어 있는 이벤트 로그를 발송합니다.
    private func dispatchBatch() {
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] dispatchBatch start!!!")
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self.dispatchBatch()
            }
            return
        }
        guard let queue = self.queue, let dispatcher = self.dispatcher else { return }
        
        queue.first(limit: numberOfEventsDispatchedAtOnce) { [weak self] events in
            guard let self = self else { return }
            
            // 큐에서 가져온 이벤트 항목이 없을 경우, 배치를 끝낼지 여부 체크..
            guard events.count > 0 else {
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] events count zero!!")
                self.isDispatching = false

                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Finish dispatching events")
                self.logger.info("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Finished dispatching events")
                
                // 로컬큐에 저장되어 있는 이벤트 정보 클리어.
                tagWorksBase?.clearLocalQueue()
                if localQueueEnabled {
                    print("[🐹🐹🐹🐹] : \(TagWorks.sharedInstance.tagWorksBase?.eventsLocalQueue ?? "Nothing!!!")")
                }
                return
            }
            
            dispatcher.send(events: events, success: { [weak self] in
                guard let self = self else { return }
                retryCount = 0
                DispatchQueue.main.async {
                    print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] dispatchBatch Send Success!! \n - \(events)")
                    queue.remove(events: events, completion: {
                        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Dispatched batch of \(events.count) events.")
                        self.logger.info("Dispatched batch of \(events.count) events.")
                        DispatchQueue.main.async {
                            self.dispatchBatch()
                        }
                    })
                }
            }, failure: { [weak self] error in
                guard let self = self else { return }
//                self.isDispatching = false
                
                if isDispatchRetry {
                    retryCount += 1
                    print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] dispatchBatch Send Failed!! - Retry Count: \(self.retryCount) \n")
                
                    if retryCount >= 3 {
                        // 실패가 발생하더라도 (전송 로스 케이스) 큐에서는 이벤트들을 삭제하고 다음 이벤트들을 전송
                        // IBK 여정분석 요청 - 2025.03.05 by Kevin
                        retryCount = 0
                        DispatchQueue.main.async {
                            queue.remove(events: events, completion: {
                                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Removed batch of \(events.count) events.")
                                self.logger.info("Removed batch of \(events.count) events.")
                                DispatchQueue.main.async {
                                    self.dispatchBatch()
                                }
                            })
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.dispatchBatch()
                        }
                    }
                } else {
                    // Retry 사용 안함
                    DispatchQueue.main.async {
                        queue.remove(events: events, completion: {
                            print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Removed batch of \(events.count) events.")
                            self.logger.info("Removed batch of \(events.count) events.")
                            DispatchQueue.main.async {
                                self.dispatchBatch()
                            }
                        })
                    }
                }
                
                self.logger.warning("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Failed dispatching events with error - \(error)")
            })
        }
    }
    
    
}


// MARK: - 수집 이벤트
extension TagWorks {
    
    @objc public func isInitialize() -> Bool {
        if self.siteId != nil && self.siteId != "" && self.dispatcher?.baseUrl != nil  {
            return true
        }
        return false
    }
    
    // 설정에 따라 큐에 넣거나 바로 전송
    func addQueueOrDispatch(_ event: Event) {
        if self.isUseIntervals || isManualDispatch {
            addQueue(event: event)
            
        } else {
            if !dispatchAtOnce(event: event) {
                logger.debug("dispatchAtOnce is Failed.")
            }
        }
    }
    
    /// Dictionary 형태의 DataBundle로 파라미터들을 받기 위해 새로 구현 - Added by Kevin 2024.07.22
    @objc public func logEvent(_ type: String, bundle: DataBundle) -> Bool {
        
        guard isInitialize() else {
            return false
        }
        
        var eventTagName: String = ""
        var eventTagParamTitle: String?
        var eventTagParamPagePath: String?
        var eventTagParamKeyword: String?
        var eventTagParamCustomPath: String?
        var eventTagParamDimenstions: [Dimension] = []
        var eventTagParamErrorMsg: String?
        
        // 값 셋팅
        // dataDictionary
        for (key, value) in bundle.dataDictionary {
            switch key {
            case DataBundle.EVENT_TAG_NAME:
                eventTagName = value
                continue
            case DataBundle.EVENT_TAG_PARAM_TITLE:
                eventTagParamTitle = value
                continue
            case DataBundle.EVENT_TAG_PARAM_PAGE_PATH:
                eventTagParamPagePath = value
                continue
            case DataBundle.EVENT_TAG_PARAM_KEYWORD:
                eventTagParamKeyword = value
                continue
            case DataBundle.EVENT_TAG_PARAM_CUSTOM_PATH:
                eventTagParamCustomPath = value
                continue
            case DataBundle.EVENT_TAG_PARAM_ERROR_MSG:
                eventTagParamErrorMsg = value
            default:
                continue
            }
        }
        // eventDimensions
        eventTagParamDimenstions.append(contentsOf: bundle.eventDimensions)
        
        // 모든 이벤트의 주체가 되는 이벤트 이름이 없는 경우, 에러를 리턴..
        if eventTagName == "" {
            logger.info("Required parameter error. - EVENT_TAG_NAME")
            return false
        }
        if let pagePath = eventTagParamPagePath {
            currentContentUrlPath = self.contentUrl?.appendingPathComponent(pagePath)
        }
        
        // LogEvent Type에 따른 분기 처리
        if type == TagWorks.EVENT_TYPE_PAGE {
            // 필수 파라미터만 체크 후 로깅 메세지 처리..
            // 실제 경로 설정은 위에서 처리함.
//            guard let pagePath = eventTagParamPagePath, let title = eventTagParamTitle else {
            guard (eventTagParamPagePath != nil), let title = eventTagParamTitle else {
                logger.info("Required parameter error. - EVENT_TAG_PARAM_PAGE_PATH, EVENT_TAG_PARAM_TITLE")
                return false
            }
            
            let event = Event(tagWorks: self, eventType: eventTagName, pageTitle: title, searchKeyword: eventTagParamKeyword, customUserPath: eventTagParamCustomPath, dimensions: eventTagParamDimenstions, errorMsg: eventTagParamErrorMsg)
            addQueueOrDispatch(event)
            
        } else {
//            let searchKeyword: String
            // Event Tag 값이 Standard Tag 값인 search 인 경우,
            if eventTagName == EventTag.SEARCH.description {
                guard eventTagParamKeyword != nil else {
                    logger.info("Required parameter error. - EVENT_TAG_PARAM_KEYWORD")
                    return false
                }
            } else if eventTagName == EventTag.ERROR.description {
                guard eventTagParamErrorMsg != nil else {
                    logger.info("Required parameter error. - EVENT_TAG_PARAM_ERROR_MESSAGE")
                    return false
                }
            }

//            urlReferer: URL(string: "urlref=카카오톡"),
            let event = Event(tagWorks: self, eventType: eventTagName, pageTitle: eventTagParamTitle, searchKeyword: eventTagParamKeyword, customUserPath: eventTagParamCustomPath, dimensions: eventTagParamDimenstions, errorMsg: eventTagParamErrorMsg)
            
            addQueueOrDispatch(event)
        }
        return true
    }
    
    // 로컬큐를 사용하여 이벤트 정보 저장 시 전송하지 못한 이벤트 정보 수집 서버로 전송
    private func sendLocalQueueEvent() -> Bool {
        guard isInitialize() else { return false }
        guard !isOptedOut else { return false }
        guard let eventString = tagWorksBase?.eventsLocalQueue else { return false }
        
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] sendLocalQueueEvent!!")
        self.isDispatching = true
        
        guard let dispatcher = self.dispatcher else { return false }
        DispatchQueue.main.async {
            dispatcher.send(localQueueEvents: eventString, success: { [weak self] in
                guard let self = self else { return }
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] sendLocalQueueEvent Send Success!!")
                self.isDispatching = false
                // 로컬큐에 저장되어 있는 이벤트 정보 클리어.
                tagWorksBase?.clearLocalQueue()
            }, failure: { [weak self] error in
                guard let self = self else { return }
                self.isDispatching = false
                self.logger.warning("Failed dispatching events with error \(error)")
            })
        }
        return true
    }
    
    // 앱 크래시가 난 경우에 고객사에서 저장한 에러 메세지가 로컬에 저장되어 있는 경우, 수집 서버로 전송
    private func sendErrorReport() {
        guard isInitialize() else { return }
        guard !isOptedOut, errorReportEnabled else { return }
        
        
        var isSuccess: Bool = true
        tagWorksBase?.crashErrorLog?.forEach { (errorLog) in
            guard let errorType = errorLog["errorType"] as? String,
                  var errorMessage = errorLog["errorData"] as? String,
                  let errorTime = errorLog["timestamp"] as? String else { return }
            
            // errorMessage는 json 파서가 인식할 수 있도록 특수문자 replace (필요없음 - 전송할때 urlEncoding을 하기 때문)
            // 연속된 공백만 공백 두칸으로 줄이기
            errorMessage = errorMessage.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: "  ")
            let dataBundle = DataBundle()
            dataBundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.ERROR)
            dataBundle.putString(DataBundle.EVENT_TAG_PARAM_ERROR_MSG, "Crash Error Log")
            
            if isUseDynamicParameter {
                dataBundle.putDynamicDimension(key: errorTypeDimensionKey, value: errorType)
                dataBundle.putDynamicDimension(key: errorDataDimensionKey, value: errorMessage)
                dataBundle.putDynamicDimension(key: errorTimeDimensionKey, value: errorTime)
            } else {
                dataBundle.putDimension(index: errorTypeDimensionIndex, value: errorType)
                dataBundle.putDimension(index: errorDataDimensionIndex, value: errorMessage)
                dataBundle.putDimension(index: errorTimeDimensionIndex, value: errorTime)
            }
            
            let event = Event(tagWorks: self, eventType: StandardEventTag.ERROR, dimensions: dataBundle.eventDimensions, errorMsg: dataBundle.dataDictionary[DataBundle.EVENT_TAG_PARAM_ERROR_MSG])
            if !dispatchAtOnce(event: event) {
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] sendErrorReport is Failed.")
//                return
                isSuccess = false
            } else {
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] sendErrorReport is Sucessed.")
            }
        }
        
        if isSuccess {
            tagWorksBase?.clearCrashErrorLog()
        }
    }
    
    // 앱 크래시가 발생하여 자동 수집된 크래쉬 로그가 로컬에 저장되어 있는 경우, 수집 서버로 전송
    private func sendCrashReport() {
        guard isInitialize() else { return }
        guard !isOptedOut, errorReportEnabled else { return }
        
        // fatalError Check
//        CrashLogManager.sharedInstance.checkAndSaveCrashIfNeeded()
        
        var isSuccess: Bool = true
        tagWorksBase?.crashErrorReport?.forEach { (errorLog) in
            guard let errorType = errorLog["errorType"] as? String,
                  var errorMessage = errorLog["errorData"] as? String,
                  let errorTime = errorLog["timestamp"] as? String else { return }
            
            // errorMessage는 json 파서가 인식할 수 있도록 특수문자 replace (필요없음 - 전송할때 urlEncoding을 하기 때문)
            // 연속된 공백만 공백 두칸으로 줄이기
            errorMessage = errorMessage.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: "  ")
            let dataBundle = DataBundle()
            dataBundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.ERROR)
//            dataBundle.putString(DataBundle.EVENT_TAG_PARAM_ERROR_MSG, "Crash Error Log")
            
            let event = Event(tagWorks: self, eventType: StandardEventTag.ERROR, errorType: errorType, errorData: errorMessage, errorTime: errorTime)
            if !dispatchAtOnce(event: event) {
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] sendErrorReport is Failed.")
//                return
                isSuccess = false
            } else {
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] sendErrorReport is Sucessed.")
            }
        }
        
        if isSuccess {
            tagWorksBase?.clearCrashErrorReport()
        }
    }
}

// MARK: - 공용 디멘전
extension TagWorks {
    
    // MARK: Dimension index 파라미터
    /*
        Index를 기반으로 디멘젼을 추가하는 방식
        - 동적 파라미터를 사용 시 해당 메소드는 사용하면 안됨!!
    */
    
    ///
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameter dimensions: 추가할 디멘전 배열 객체
    ///
    @objc public func setCommonDimension(dimensions: [Dimension]) {
        // 중복 항목을 제거한 후, array 추가
        for dimension in dimensions {
            removeCommonDimension(WithType: dimension.type, index: dimension.index)
        }
        self.dimensions.append(contentsOf: dimensions)
    }
    
    @objc public func setCommonDimensions(_ dimensions: [Dimension]) {
        // 중복 항목을 제거한 후, array 추가
        for dimension in dimensions {
            removeCommonDimension(WithType: dimension.type, index: dimension.index)
        }
        self.dimensions.append(contentsOf: dimensions)
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameter dimension: 추가할 디멘전 객체
    @objc public func setCommonDimension(dimension: Dimension){
        removeCommonDimension(WithType: dimension.type, index: dimension.index)
        self.dimensions.append(dimension)
    }
    
    @objc public func setCommonDimension(_ dimension: Dimension){
        removeCommonDimension(WithType: dimension.type, index: dimension.index)
        self.dimensions.append(dimension)
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - index: 추가할 디멘전 index
    ///   - stringValue: 추가할 디멘전 value (d - String 타입)
    @objc public func setCommonDimension(index: Int, stringValue: String) {
        setCommonDimension(dimension: Dimension(WithType: Dimension.generalType, index: index, stringValue: stringValue, numValue: -1))
    }
    
    @objc public func setCommonDimension(index: Int, value: String) {
        setCommonDimension(dimension: Dimension(WithType: Dimension.generalType, index: index, stringValue: value, numValue: -1))
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - index: 추가할 디멘전 index
    ///   - numValue: 추가할 디멘전 value (f - Double 타입)
    @objc public func setCommonDimension(index: Int, numValue: Double) {
        setCommonDimension(dimension: Dimension(WithType: Dimension.factType, index: index, stringValue: "", numValue: numValue))
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - type: 추가할 디멘전 type
    ///   - index: 추가할 디멘전 index
    ///   - stringValue: 추가할 디멘전 value (d - String 타입)
    ///   - numValue: 추가할 디멘전 value (f - Double 타입)
//    @objc public func setCommonDimension(index: Int, value: String){
//        setCommonDimension(dimension: Dimension(index: index, value: value))
    @objc public func setCommonDimension(type: Int, index: Int, stringValue: String, numValue: Double) {
        setCommonDimension(dimension: Dimension(WithType: type, index: index, stringValue: stringValue, numValue: numValue))
    }
    
    /// 수집 로그의 공용 디멘전을 제거합니다.
    /// - Parameters:
    ///  - WithType: 디멘전 type
    ///  - index: 디멘전 index
    @objc public func removeCommonDimension(WithType type: Int, index: Int) {
        self.dimensions.removeAll(where: {$0.index == index && $0.type == type})
//        self.dimensions = self.dimensions.filter({
//            dimension in (dimension.type != type && dimension.index != index)
//        })
    }
    
    @objc public func removeCommonDimensionWithArrayIndex(_ index: Int) {
        self.dimensions.remove(at: index)
    }
    
    @objc public func removeAllCommonDimension() {
        dimensions.removeAll()
    }
    
    /// 수집 로그의 공용 디멘전을 가져옵니다.
    /// - Parameters:
    ///  - WithType: 디멘전 type
    ///  - index: 디멘전 index
    @objc public func getCommonDimension(WithType type: Int, index: Int) -> Dimension? {
        return self.dimensions.filter {$0.index == index && $0.type == type}.first
    }
    
    @objc public func getCommonDimensions() -> [Dimension] {
        return self.dimensions
    }
    
    // MARK: Dimension 동적 파라미터
    /*
        동적 파라미터(키값을 스트링으로 가지는)를 기반으로 디멘젼을 추가하는 방식
        - Index 파라미터를 사용 시 해당 메소드는 사용하면 안됨!!
    */
    
    ///
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameter dimensions: 추가할 디멘전 배열 객체
    ///
    @objc public func setDynamicCommonDimension(dimensions: [Dimension]) {
        // 중복 항목을 제거한 후, array 추가
        for dimension in dimensions {
            removeDynamicCommonDimension(key: dimension.key)
        }
        self.dimensions.append(contentsOf: dimensions)
    }
    
    @objc public func setDynamicCommonDimensions(_ dimensions: [Dimension]) {
        // 중복 항목을 제거한 후, array 추가
        for dimension in dimensions {
            removeDynamicCommonDimension(key: dimension.key)
        }
        self.dimensions.append(contentsOf: dimensions)
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameter dimension: 추가할 디멘전 객체
    @objc public func setDynamicCommonDimension(dimension: Dimension){
        removeDynamicCommonDimension(key: dimension.key)
        self.dimensions.append(dimension)
    }
    
    @objc public func setDynamicCommonDimension(_ dimension: Dimension){
        removeDynamicCommonDimension(key: dimension.key)
        self.dimensions.append(dimension)
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - index: 추가할 디멘전 index
    ///   - stringValue: 추가할 디멘전 value (d - String 타입)
    @objc public func setDynamicCommonDimension(key: String, stringValue: String) {
        setDynamicCommonDimension(dimension: Dimension(key: key, value: stringValue))
    }
    
    @objc public func setDynamicCommonDimension(key: String, value: String) {
        setDynamicCommonDimension(dimension: Dimension(key: key, value: value))
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - index: 추가할 디멘전 index
    ///   - numValue: 추가할 디멘전 value (f - Double 타입)
    @objc public func setDynamicCommonDimension(key: String, numValue: Double) {
        setDynamicCommonDimension(dimension: Dimension(key: key, numValue: numValue))
    }
    
    // 필요 없다고 판단되어 인터페이스 삭제 - 2025.01.24 by Kevin (v.1.1.22)
//    /// 수집 로그의 공용 디멘전을 지정합니다.
//    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
//    /// - Parameters:
//    ///   - type: 추가할 디멘전 type
//    ///   - index: 추가할 디멘전 index
//    ///   - stringValue: 추가할 디멘전 value (d - String 타입)
//    ///   - numValue: 추가할 디멘전 value (f - Double 타입)
////    @objc public func setCommonDimension(index: Int, value: String){
////        setCommonDimension(dimension: Dimension(index: index, value: value))
//    @objc public func setCommonDimension(type: Int, index: Int, stringValue: String, numValue: Double) {
//        setCommonDimension(dimension: Dimension(WithType: type, index: index, stringValue: stringValue, numValue: numValue))
//    }
    
    /// 수집 로그의 공용 디멘전을 제거합니다.
    /// - Parameters:
    ///  - WithType: 디멘전 type
    ///  - index: 디멘전 index
    @objc public func removeDynamicCommonDimension(key: String) {
        self.dimensions.removeAll(where: {$0.key == key})
    }
    
    @objc public func removeDynamicCommonDimensionWithArrayIndex(_ index: Int) {
        self.dimensions.remove(at: index)
    }
    
    @objc public func removeAllDynamicCommonDimension() {
        dimensions.removeAll()
    }
    
    /// 수집 로그의 공용 디멘전을 가져옵니다.
    /// - Parameters:
    ///  - WithType: 디멘전 type
    ///  - index: 디멘전 index
    @objc public func getDynamicCommonDimension(key: String) -> Dimension? {
        return self.dimensions.filter {$0.key == key}.first
    }
    
    @objc public func getDynamicCommonDimensions() -> [Dimension] {
        return self.dimensions
    }
}

// MARK: WebView 인터페이스
/// WebView Interface
extension TagWorks: WebInterfaceDelegate {
    
    func isEqualSiteId(idsite: String) -> Bool {
        if self.siteId == idsite {
            return true
        }
        
        return false
    }
    
    func addWebViewEvent(event: Event) {
        addQueueOrDispatch(event)
    }
}

/// Campaign Interface
/// 1차 - Scheme를 통해 유입되는 경로를 urlref 항목 셋팅을 통해 이벤트 발송
/// 2차 - Defferred Deep Link까지 구현하여 설치 경로까지 이벤트 발송
extension TagWorks {
    
    // 유입 경로가 URL로 넘어올 경우,
    @objc public func sendReferrerEvent(openURL: URL) {
        let eventType = EventTag.REFERRER.description
        let urlref = openURL
        
        let campaignEvent = Event(tagWorks: self, urlReferer: urlref, eventType: eventType)
        addQueueOrDispatch(campaignEvent)
    }
    
    // 유입 경로가 특정 항목일 경우,
    @objc public func sendReferrerEvent(referrer: String) {
        let eventType = EventTag.REFERRER.description
        let referrerEvent = Event(tagWorks: self, eventType: eventType, inflow: referrer)
        
        addQueueOrDispatch(referrerEvent)
    }
}

// MARK: 앱 크래쉬 로그 수집 및 저장
extension TagWorks {
    
    // MARK: 앱 크래시 발생한 경우, 해당 인터페이스를 통해 로컬 저장 및 재실행 시 서버 전송
    // 앱이 크래쉬가 난 경우, 해당 함수를 통해 로컬 영역에 저장
    // 공통 디멘전을 이용하기 위한 저장
    @objc public func saveErrorReport(errorType: String, errorMessage: String) {
        guard !isOptedOut, errorReportEnabled else { return }
        CrashLogManager.sharedInstance.saveErrorStackTrace(errorType: errorType, errorMessage: errorMessage)
    }
    
    // TagWorks SDK에서 자동 수집되어 저장
    func saveCrashReport(errorType: String, errorMessage: String) {
        guard !isOptedOut, errorReportEnabled else { return }
        CrashLogManager.sharedInstance.saveErrorStackTrace(errorType: errorType, errorMessage: errorMessage, isTagWorks: true)
    }
}
