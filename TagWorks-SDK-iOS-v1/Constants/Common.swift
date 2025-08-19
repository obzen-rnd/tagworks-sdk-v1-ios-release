//
//  Common.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

/// 태그 이벤트 트리거를 열거합니다.
/// EVENT_TAG_NAME 키 사용에 들어갈 Standard Tag 값
@objc public enum EventTag: Int {
    case PAGE_VIEW      = 10
    case CLICK          = 20
    case SCROLL         = 30
    case DOWNLOAD       = 40
    case OUT_LINK       = 50
    case SEARCH         = 60
    case ERROR          = 70
    case REFERRER       = 80
    case BACKGROUND     = 90
    case FOREGROUND     = 100
    case DEEPLINK       = 110
    case APP_PUSH       = 120
    
    
    public var description: String {
        switch self {
            case .PAGE_VIEW: return "PageView"
            case .CLICK:     return "Click"
            case .SCROLL:    return "Scroll"
            case .DOWNLOAD:  return "Download"
            case .OUT_LINK:  return "OutLink"
            case .SEARCH:    return "Search"
            case .ERROR:     return "Error"
            case .REFERRER:  return "Referrer"
            case .BACKGROUND: return "oz_Background"
            case .FOREGROUND: return "oz_Foreground"
            case .DEEPLINK:   return "oz_DeepLink"
            case .APP_PUSH:   return "oz_AppPush"
        }
    }
}


/// Objective-C
///// Objective-C에서 사용할 EventTag Class
@objc public class StandardEventTag: NSObject {
    @objc static public func toString(eventTag: EventTag) -> String {
        return eventTag.description
    }
    
    @objc static public let PAGE_VIEW   = "PageView"
    @objc static public let CLICK       = "Click"
    @objc static public let SCROLL      = "Scroll"
    @objc static public let DOWNLOAD    = "Download"
    @objc static public let OUT_LINK    = "OutLink"
    @objc static public let SEARCH      = "Search"
    @objc static public let ERROR       = "Error"
    @objc static public let REFERRER    = "Referrer"
    @objc static public let BACKGROUND  = "oz_Background"
    @objc static public let FOREGROUND  = "oz_Foreground"
    @objc static public let DEEPLINK    = "oz_DeepLink"
    @objc static public let APP_PUSH    = "oz_AppPush"
}

///
extension TagWorksBase {
    
    /// TagWokrs UserDefault 저장 Key를 열거합니다.
    internal struct UserDefaultKey {
        static let userId                   = "TagWorksUserIdKey"
        static let visitorId                = "TagWorksVisitorIdKey"
        static let optOut                   = "TagWorksOptOutKey"
        static let eventsLocalQueue         = "TagWorksLocalQueueKey"
        static let errorLog                 = "TagWorksErrorLogKey"             // IBK 고객여정에서 요청한 앱 크래시 경우에 에러 로그 저장 용도 - by Kevin. 2025. 05. 13
        static let errorReport              = "TagWorksErrorReportKey"          // SDK 내부 기능으로 앱 크래시 경우 자동 탐지 후 에러 리포트 스택 트레이스를 저장 용도
        static let isAppFirstLaunch         = "TagWorksIsAppFirstLaunchKey"     // 앱이 설치 후 최초 실행 여부 판단
        static let appInstallTime           = "TagWorksAppInstallTimeKey"
        static let pushTokenKey             = "TagWorksPushTokenKey"
        static let lastSentPushTokenDateKey = "TagWorksLastSentPushTokenDateKey"
    }
}

// MARK: 이벤트 타입 및 앱 스키마 Define
extension TagWorks {
//    static private let CAMPAIGN_SCHEME = "OBZEN_CAMPAIGN"
    static public let CAMPAIGN_SCHEME = "obzentagworks"
    
    /// 필수 파라미터 정의
    /// 1. EVENT_TYPE_PAGE
    ///  - EVENT_TAG_NAME
    ///  - EVENT_TAG_PARAM_TITLE
    ///  - EVENT_TAG_PARAM_PAGE_PATH
    ///
    /// 2. EVENT_TYPE_USER_EVENT
    ///  - EVENT_TAG_NAME
    ///  - # EVENT_TAG_NAME 이 EventTag.search.description 인 경우,
    ///   --> EVENT_TAG_PARAM_KEYWORD
    
    @objc static public let EVENT_TYPE_PAGE: String          = "EVENT_TYPE_PAGE"
    @objc static public let EVENT_TYPE_USER_EVENT: String    = "EVENT_TYPE_USER_EVENT"
}


extension Event {
    
    /// 이벤트 로그 http request 에 지정되는 파라미터를 열거합니다.
    internal struct URLQueryParams {
        static let siteId           = "idsite"
        static let visitorId        = "ozvid"
        static let userId           = "uid"
        static let language         = "lang"
        static let url              = "url"
        static let urlReferer       = "urlref"
        static let event            = "e_c"
        static let clientDateTime   = "cdt"
        static let screenSize       = "res"
    }
    
    /// 이벤트 카테고리 내에 지정되는 TagWorks 이벤트 파라미터를 열거합니다.
    internal struct EventParams {
        static let visitorId                = "ozvid"
        static let clientDateTime           = "obz_client_date"
        static let triggerType              = "obz_trg_type"
        static let pageTitle                = "epgtl_nm"
        static let customUserPath           = "obz_user_path"
        static let searchKeyword            = "obz_search_keyword"
        static let customDimensionD         = "cstm_d"
        static let customDimensionF         = "cstm_f"
        static let dynamicDimension         = "item"
        static let dynamicDimensionString   = "st"
        static let dynamicDimensionNumeric  = "nu"
        static let deviceType               = "obz_dvc_type"
        static let appVersion               = "obz_app_vsn"
        static let appName                  = "obz_app_nm"
        static let errorMessage             = "obz_error"
        static let inflowChannel            = "obz_inflow"
        static let errorType                = "obz_err_type"
        static let errorData                = "obz_err_data"
        static let errorTime                = "obz_err_time"
        static let adId                     = "obz_ad_id"
        static let eventPlatform            = "obz_evt_platfm"          // 1 - Native, 2 - WebView
        static let pushToken                = "obz_ptoken"
        // 딥링크 정보
        static let isDeepLink               = "obz_dlk"
        static let isDeferredDeepLink       = "obz_dfrd_dlk"
        static let deeplinkId               = "obz_dlk_id"
        static let isFirstInstall           = "obz_frst_instl"
        static let isReinstall              = "obz_re_instl"
        static let campaignId               = "obz_dlk_camp_id"
        static let refChannel               = "obz_dlk_infmd"
        static let landingPageUrl           = "obz_dlk_dstpt"
    }
}

// MARK: TagWorksPopup 에서 사용될 타입들 정의

//@objc public class InAppPopupType: NSObject {
//    @objc static public let centerPopup         = 1
//    @objc static public let bottomPopup         = 2
//    @objc static public let pagePopup           = 3
//    @objc static public let topPopup            = 4
//}
//
//@objc public class InAppPopupButtonType: NSObject {
//    @objc static public let none                = 0
//    @objc static public let close               = 1
//    @objc static public let closeAndNoMoreShow  = 2
//    @objc static public let closeAndNoShowToday = 3
//    @objc static public let closeAndNoShowSeven = 4
//}

@objc public enum InAppPopupType: Int {
    case center     = 1
    case bottom     = 2
    case page       = 3
    case top        = 4
}

@objc public enum InAppPopupButtonType: Int {
    case none                = 0
    case close               = 1
    case closeAndNoMoreShow  = 2
    case closeAndNoShowToday = 3
    case closeAndNoShowSeven = 4
}


// MARK: IBK 고객여정에서 사용하는 에러 로그 전송 Dimension Index/Key
let errorTypeDimensionIndex         = 901
let errorDataDimensionIndex         = 902
let errorTimeDimensionIndex         = 903

let errorTypeDimensionKey            = "obz_err_type"
let errorDataDimensionKey            = "obz_err_data"
let errorTimeDimensionKey            = "obz_err_time"

