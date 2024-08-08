//
//  TagWorks.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

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
    private var queue: Queue?
    
    /// 수집된 로그를 발송하는 객체입니다.
    private var dispatcher: Dispatcher?
    
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
                return existingId
            }
            let id = UUID().uuidString.lowercased()
            tagWorksBase?.visitorId = id
            return id
        }
        set {
            tagWorksBase?.visitorId = newValue
        }
    }
    
    /// 수집되는 사용자의 유저 식별자 (고객 식별자)입니다.
    ///  - 로그인되어 사용하는 사용자의 유저 식별자입니다. (사이트에서 전달받음)
    @objc public var userId: String? {
        get {
            return tagWorksBase?.userId
        }
        set {
            tagWorksBase?.userId = newValue
        }
    }
    
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
    
    // 필수 설정값 end
    //-----------------------------------------
    
    /// 공통으로 저장되는 디멘전 컬렉션입니다.
    /// * 해당 컬렉션에 저장된 디멘전은 모든 이벤트 호출시 자동으로 들어갑니다.
    /// * 이벤트 호출시 디멘전을 별도로 추가 한 경우 우선적으로 나중에 호출된 디멘전이 저장됩니다.
    internal var dimensions: [Dimension] = []
    
    /// 수집되는 어플리케이션의 기본 Url 주소입니다.
    /// * 수집대상이 되는 어플리케이션의 bundleIdentifier 주소를 기본으로 하며, 별도 지정시 지정된 값으로 수집됩니다.
    @objc public var contentUrl: URL?
    
    /// 수집되는 어플리케이션의 현재 Url 주소입니다.
    /// * PageView 이벤트 호출시 contentUrl + 지정된 Url 경로 순으로 수집됩니다.
    @objc public var currentContentUrlPath: URL?
    
    /// 한번에 발송할 수 있는 이벤트 구조체의 수입니다.
    private let numberOfEventsDispatchedAtOnce = 20
    
    /// 현재 이벤트 로그 발송중 여부입니다.
    private(set) var isDispatching = false
    
    /// 이벤트 로그의 발송 주기 입니다. (단위 : 초)
    /// * 발송 주기의 기본값은 10 입니다.
    /// * 값을 0으로 지정하는 경우 이벤트 수집 즉시 발송됩니다.
    /// * 값을 0이하로 지정하는 경우 이벤트 로그 발송을 자동으로 수행하지 않습니다.
    ///     - dispatch() 함수를 이용하여 수동으로 발송해야 합니다.
    @objc public var dispatchInterval: TimeInterval = 5.0
//    {
//        didSet {
//            startDispatchTimer()
//        }
//    }
    
    private var dispatchTimer: Timer?
    
    ///
    @objc public let webViewInterface: WebInterface = WebInterface()

    
    // MARK: - 클래스 객체 함수
    
    /// 이벤트 전송에 필요한 필수 항목 입력
    /// - Parameters:
    ///   - siteId: 수집 대상이 되는 사이트(고객사) 식별자
    ///   - baseUrl: 수집 로그 발송을 위한 서버 URL
    ///   - userAgent: 수집 대상의 userAgent 객체 String
//    public func setEnvironment(siteId: String, baseUrl: URL, userAgent: String?) {
    @objc public func setInstanceConfig(siteId: String,
                                        baseUrl: URL,
                                        dispatchInterval: TimeInterval,
                                        userAgent: String? = nil,
                                        appVersion: String? = nil,
                                        appName: String? = nil) {
        self.siteId = siteId
        self.dispatchInterval = dispatchInterval
        self.queue = DefaultQueue()
        self.dispatcher = DefaultDispatcher(serializer: EventSerializer(), baseUrl: baseUrl, userAgent: userAgent)
        self.appVersion = appVersion
        self.appName = appName
        self.tagWorksBase = TagWorksBase(suitName: "\(siteId)\(baseUrl.absoluteString)")
        self.contentUrl = URL(string: "APP://\(AppInfo.getApplicationInfo().bundleIdentifier ?? "")")
//        self.contentUrl = URL(string: "http://\(AppInfo.getApplicationInfo().bundleIdentifier ?? "")")
        startDispatchTimer()
        
        self.webViewInterface.delegate = self
    }
    
    /// 이벤트 로그 발생 주기 타이머를 시작합니다.
    private func startDispatchTimer() {
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
    
    /// ## 이벤트 발송 관련 함수 ##
    
    /// 현재 Queue에 저장되어 있는 이벤트 구조체를 즉시 발송합니다. (수동 처리)
    @objc public func dispatch() {
        guard !isDispatching else {
            logger.verbose("is already dispatching.")
            return
        }
        guard let queue = self.queue, queue.size > 0 else {
            print("Dispatch queue is empty.")
            logger.info("No need to dispatch. Dispatch queue is empty.")
            startDispatchTimer()
            return
        }
        logger.info("Start dispatching events")
        isDispatching = true
        dispatchBatch()
    }
    
    /// 현재 Queue에 저장되어 있는 이벤트 로그를 발송합니다.
    private func dispatchBatch() {
        print("dispatchBatch start!!!")
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self.dispatchBatch()
            }
            return
        }
        guard var queue = self.queue, let dispatcher = self.dispatcher else { return }
        queue.first(limit: numberOfEventsDispatchedAtOnce) { [weak self] events in
            guard let self = self else { return }
            guard events.count > 0 else {
                print("events count zero!!")
                self.isDispatching = false
                self.startDispatchTimer()
                self.logger.info("Finished dispatching events")
                return
            }
            dispatcher.send(events: events, success: { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    print("send - \(events)")
                    queue.remove(events: events, completion: {
                        self.logger.info("Dispatched batch of \(events.count) events.")
                        DispatchQueue.main.async {
                            self.dispatchBatch()
                        }
                    })
                }
            }, failure: { [weak self] error in
                guard let self = self else { return }
                self.isDispatching = false
                self.startDispatchTimer()
                self.logger.warning("Failed dispatching events with error \(error)")
            })
        }
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
        logger.verbose("Added queue event: \(event)")
        
        guard var queue = self.queue else { return }
        queue.enqueue(event: event)
        print(queue.size)
    }
}


// MARK: - 수집 이벤트
extension TagWorks {
    
    /// Dictionary 형태의 DataBundle로 파라미터들을 받기 위해 새로 구현 - Added by Kevin 2024.07.22
    @objc public func logEvent(_ type: String, bundle: DataBundle) {
        var eventTagName: String = ""
        var eventTagParamTitle: String?
        var eventTagParamPagePath: String?
        var eventTagParamKeyword: String?
        var eventTagParamCustomPath: String?
        var eventTagParamDimenstions: [Dimension] = []
        
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
            default:
                continue
            }
        }
        // eventDimensions
        eventTagParamDimenstions.append(contentsOf: bundle.eventDimensions)
        
        // 모든 이벤트의 주체가 되는 이벤트 이름이 없는 경우, 에러를 리턴..
        if eventTagName == "" {
            logger.info("Required parameter error. - EVENT_TAG_NAME")
            return
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
                return
            }
            
//            currentContentUrlPath = self.contentUrl?.appendingPathComponent(pagePath)
            let event = Event(tagWorks: self, eventType: eventTagName, pageTitle: title, searchKeyword: eventTagParamKeyword, customUserPath: eventTagParamCustomPath, dimensions: eventTagParamDimenstions)
            addQueue(event: event)
            
        } else {
//            let searchKeyword: String
            // Event Tag 값이 Standard Tag 값인 search 인 경우,
            if eventTagName == EventTag.search.description {
                guard let keyword = eventTagParamKeyword else {
                    logger.info("Required parameter error. - EVENT_TAG_PARAM_KEYWORD")
                    return
                }
//                searchKeyword = keyword
                let event = Event(tagWorks: self, eventType: eventTagName, pageTitle: eventTagParamTitle, searchKeyword: keyword, customUserPath: eventTagParamCustomPath, dimensions: eventTagParamDimenstions)
                addQueue(event: event)
            } else {
                let event = Event(tagWorks: self, eventType: eventTagName, pageTitle: eventTagParamTitle, searchKeyword: eventTagParamKeyword, customUserPath: eventTagParamCustomPath, dimensions: eventTagParamDimenstions)
                addQueue(event: event)
            }
        }
    }
    
//    /// 사용자 지정 이벤트를 수집합니다.
//    /// - Parameter event: 사용자 지정 이벤트 객체
//    public func event(_ event: Event){
//        addQueue(event: event)
//    }
//    
//    /// 이벤트를 수집합니다.
//    /// - Parameters:
//    ///   - eventType: 이벤트 발생 유형
//    ///   - dimensions: 사용자 정의 디멘전
//    ///   - customUserPath: 사용자 정의 경로
//    public func event(eventType: String, dimensions: [Dimension] = [], customUserPath: String? = nil){
//        let event = Event(tagWorks: self, eventType: eventType, customUserPath: customUserPath, dimensions: dimensions)
//        addQueue(event: event)
//    }
//    
//    /// 이벤트를 수집합니다.
//    /// - Parameters:
//    ///   - eventType: 이벤트 발생 유형
//    ///   - dimensions: 사용자 정의 디멘전
//    ///   - customUserPath: 사용자 정의 경로
//    @objc public func event(eventType: EventTag, dimensions: [Dimension] = [], customUserPath: String? = nil){
//        event(eventType: eventType.eventString, dimensions: dimensions, customUserPath: customUserPath)
//    }
//    
//    
//    /// 현재 사용자의 페이지를 수집합니다.
//    /// - Parameters:
//    ///   - pagePath: 현재 페이지 경로
//    ///   - pageTitle: 현재 페이지 제목
//    ///   - dimensions: 사용자 정의 디멘전
//    ///   - customUserPath: 사용자 정의 경로
//    @objc public func pageView(pagePath: [String], pageTitle: String?, dimensions: [Dimension] = [], customUserPath: String? = nil){
//        currentContentUrlPath = self.contentUrl?.appendingPathComponent(pagePath.joined(separator: "/"))
//        let event = Event(tagWorks: self, eventType: Tag.pageView.event, pageTitle: pageTitle, customUserPath: customUserPath, dimensions: dimensions)
//        queue(event: event)
//    }
//    
//    /// 검색 키워드를 수집합니다.
//    /// - Parameters:
//    ///   - keyword: 검색 키워드
//    ///   - dimensions: 사용자 정의 디멘전
//    ///   - customUserPath: 사용자 정의 경로
//    @objc public func searchKeyword(keyword: String, dimensions: [Dimension] = [], customUserPath: String? = nil){
//        let event = Event(tagWorks: self, eventType: Tag.search.event, searchKeyword: keyword, customUserPath: customUserPath, dimensions: dimensions)
//        queue(event: event)
//    }
}

// MARK: - 공용 디멘전
extension TagWorks {
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameter dimension: 추가할 디멘전 객체
    @objc public func setCommonDimension(dimension: Dimension){
        removeCommonDimension(WithType: dimension.type, index: dimension.index)
        self.dimensions.append(dimension)
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
    /// - Parameter index: 삭제할 디멘전 index
    @objc public func removeCommonDimension(WithType type: Int, index: Int){
        self.dimensions.removeAll(where: {$0.index == index && $0.type == type})
//        self.dimensions = self.dimensions.filter({
//            dimension in (dimension.type != type && dimension.index != index)
//        })
    }
}

extension TagWorks {
    @objc static public let EVENT_TYPE_PAGE: String          = "EVENT_TYPE_PAGE"
    @objc static public let EVENT_TYPE_USER_EVENT: String    = "EVENT_TYPE_USER_EVENT"

    /// 필수 파라미터 정의
    /// 1. EVENT_TYPE_PAGE
    ///  - EVENT_TAG_NAME
    ///  - EVENT_TAG_PARAM_PAGE_PATH
    ///  - EVENT_TAG_PARAM_TITLE
    ///
    /// 2. EVENT_TYPE_USER_EVENT
    ///  - EVENT_TAG_NAME
    ///  - # EVENT_TAG_NAME 이 EventTag.search.description 인 경우,
    ///   -> EVENT_TAG_PARAM_KEYWORD
    ///
}

/// WebView Interface
extension TagWorks: WebInterfaceDelegate {
    
    func isEqualSiteId(idsite: String) -> Bool {
        if self.siteId == idsite {
            return true
        }
        
        return false
    }
    
    func addWebViewEvent(event: Event) {
        addQueue(event: event)
    }
    
}
