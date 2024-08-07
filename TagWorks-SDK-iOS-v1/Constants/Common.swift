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
    case click      = 10
    case search     = 20
    case pageView   = 30
    case scroll     = 40
    
    public var description: String {
        switch self {
        case .click:    return "Click"
        case .search:   return "Search"
        case .pageView: return "PageView"
        case .scroll:   return "Scroll"
        }
    }
}


/// Objective-C
///// Objective-C에서 사용할 EventTag Class
@objc public class StandardEventTag: NSObject {
//    static public func EventTagString(eventTag: EventTag) -> String {
//        switch eventTag {
//        case .click:    return "Click"
//        case .search:   return "Search"
//        case .pageView: return "PageView"
//        case .scroll:   return "Scroll"
//        }
//    }
    @objc static public func toString(eventTag: EventTag) -> String {
        switch eventTag {
        case .click:    return "Click"
        case .search:   return "Search"
        case .pageView: return "PageView"
        case .scroll:   return "Scroll"
        }
    }
}

///
extension TagWorksBase {
    
    /// TagWokrs UserDefault 저장 Key를 열거합니다.
    internal struct UserDefaultKey {
        static let userId       = "TagWorksUserIdKey"
        static let visitorId    = "TagWorksVisitorIdKey"
        static let optOut       = "TagWorksOptOutKey"
    }
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
    
    /// 이벤트 로그 http request 내에 지정되는 TagWorks 이벤트 파라미터를 열거합니다.
    internal struct EventParams {
        static let visitorId        = "ozvid"
        static let clientDateTime   = "obz_client_date"
        static let triggerType      = "obz_trg_type"
        static let customUserPath   = "obz_user_path"
        static let searchKeyword    = "obz_search_keyword"
        static let customDimensionD = "cstm_d"
        static let customDimensionF = "cstm_f"
        static let pageTitle        = "epgtl_nm"
        static let deviceType       = "obz_dvc_type"
        static let appVersion       = "obz_app_vsn"
        static let appName          = "obz_app_nm"
    }
}


