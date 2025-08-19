//
//  EventSerializer.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import Foundation

/// 로그 송신을 위한 직렬화 인터페이스를 상속받는 구현체 클래스입니다.
final class EventSerializer: Serializer {
    
    /// 이벤트 구조체에 저장된 프로퍼티를 String 형태의 Map으로 반환합니다.
    /// - Parameter event: 이벤트 구조체
    /// - Returns: 이벤트 프로퍼티 Map
    internal func queryItems(for event: Event) -> [String : String] {
        event.queryItems.reduce(into: [String : String]()) {
            $0[$1.name] = $1.value
        }
    }
    
    internal func queryItemsWithLocalQueue(for event: Event) -> [String : String] {
        event.queryItemsWithLocalQueue.reduce(into: [String : String]()) {
            $0[$1.name] = $1.value
        }
    }
    
    /// queue에서 이벤트 구조체를 반환합니다.
    /// - Parameter events: 이벤트 구조체 컬렉션
    /// - Returns: Json Data
    internal func toJsonData(for events: [Event], isLocalQueue: Bool = false) throws -> Data {
        let eventsAsQueryItems: [[String: String]] = events.map { isLocalQueue == false ? self.queryItems(for: $0) : self.queryItemsWithLocalQueue(for: $0) }
        let serializedEvents = eventsAsQueryItems.map { items in
            items.map {
                "\($0.key)=\($0.value)"
            }.joined(separator: "&")
        }
    
        let body: [String : [String]]  = ["requests": serializedEvents.map({ "?\($0)" })]
//        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Event Json Data: \(body)")
    
        // JSONSerialization.data(withJSONObject:) 함수를 사용하면 안전한 JSON 사용을 위해 '\','\\' 문자가 자동으로 붙어서 인코딩 됨.
        return try JSONSerialization.data(withJSONObject: body, options: [])
    }
}

fileprivate extension Event {
    
    /// Tag 이벤트 정보를 직렬화 합니다.
    /// - Returns: Tag 이벤트 로그
    private func serializeEventString() -> String {
        var eventCommonItems: [URLQueryItem] = []
        eventCommonItems.append(URLQueryItem(name: EventParams.clientDateTime, value: CommonUtil.Formatter.iso8601DateFormatter.string(from: clientDateTime)))
        eventCommonItems.append(URLQueryItem(name: EventParams.triggerType, value: eventType))
        eventCommonItems.append(URLQueryItem(name: EventParams.visitorId, value: visitorId))
        
        if let pageTitle = self.pageTitle {
            eventCommonItems.append(URLQueryItem(name: EventParams.pageTitle, value: pageTitle))
        }
        if let searchKeyword = self.searchKeyword {
            eventCommonItems.append(URLQueryItem(name: EventParams.searchKeyword, value: searchKeyword))
        }
        if let customUserPath = self.customUserPath {
            eventCommonItems.append(URLQueryItem(name: EventParams.customUserPath, value: customUserPath))
        }
        if let errorMsg = self.errorMsg {
            eventCommonItems.append(URLQueryItem(name: EventParams.errorMessage, value: errorMsg))
        }
        if let inflow = self.inflow {
            eventCommonItems.append(URLQueryItem(name: EventParams.inflowChannel, value: inflow))
        }
        if let errorType = self.errorType {
            eventCommonItems.append(URLQueryItem(name: EventParams.errorType, value: errorType))
        }
        if let errorData = self.errorData {
            eventCommonItems.append(URLQueryItem(name: EventParams.errorData, value: errorData))
        }
        if let errorTime = self.errorTime {
            eventCommonItems.append(URLQueryItem(name: EventParams.errorTime, value: errorTime))
        }
        
        eventCommonItems.append(URLQueryItem(name: EventParams.eventPlatform, value: evtPlatform))
        
        if let adId = self.adId {
            eventCommonItems.append(URLQueryItem(name: EventParams.adId, value: adId))
        }
        // 딥링크 정보
        if let isDeepLink = self.isDeepLink {
            eventCommonItems.append(URLQueryItem(name: EventParams.isDeepLink, value: isDeepLink))
        }
        if let isDeferredDeepLink = self.isDeferredDeepLink {
            eventCommonItems.append(URLQueryItem(name: EventParams.isDeferredDeepLink, value: isDeferredDeepLink))
        }
        if let deeplinkId = self.deeplinkId {
            eventCommonItems.append(URLQueryItem(name: EventParams.deeplinkId, value: deeplinkId))
        }
        if let isFirstInstall = self.isFirstInstall {
            eventCommonItems.append(URLQueryItem(name: EventParams.isFirstInstall, value: isFirstInstall))
        }
        if let isReinstall = self.isReinstall {
            eventCommonItems.append(URLQueryItem(name: EventParams.isReinstall, value: isReinstall))
        }
        if let campaignId = self.campaignId {
            eventCommonItems.append(URLQueryItem(name: EventParams.campaignId, value: campaignId))
        }
        if let refChannel = self.refChannel {
            eventCommonItems.append(URLQueryItem(name: EventParams.refChannel, value: refChannel))
        }
        if let landingPageUrl = self.landingPageUrl {
            eventCommonItems.append(URLQueryItem(name: EventParams.landingPageUrl, value: landingPageUrl))
        }
        if let pushToken = self.pushToken {
            eventCommonItems.append(URLQueryItem(name: EventParams.pushToken, value: pushToken))
        }
        
        eventCommonItems.append(URLQueryItem(name: EventParams.deviceType, value: "app"))
        eventCommonItems.append(URLQueryItem(name: EventParams.appVersion, value: TagWorks.sharedInstance.appVersion ?? AppInfo.getBundleShortVersion()))
        eventCommonItems.append(URLQueryItem(name: EventParams.appName, value: TagWorks.sharedInstance.appName ?? AppInfo.getBundleName()))
        
        // index 기반 디멘젼인지 동적 파라미터인지 여부 판별 후 분기
        var customDimensionItems: [URLQueryItem] = []
        if TagWorks.sharedInstance.isUseDynamicParameter == false {
            var dimensionIndex = 0
            var lastDimension: [Dimension] = []
            for dimension in self.dimensions {
                // 최대 인덱스를 가져옴
                if dimensionIndex <= dimension.index {
                    dimensionIndex = dimension.index
                }
                
                if dimension.index != -1 {
                    if dimension.type == Dimension.generalType {
                        customDimensionItems.append(URLQueryItem(name: EventParams.customDimensionD + "\(dimension.index)", value: dimension.value))
                    } else if dimension.type == Dimension.factType {
                        customDimensionItems.append(URLQueryItem(name: EventParams.customDimensionF + "\(dimension.index)", value: String(dimension.numValue)))
                    }
                } else {
                    lastDimension.append(dimension)
                }
            }
            // 정적 디멘젼이 아닌 동적 디멘젼을 사용해서 추가한 경우 예외 처리
            if lastDimension.isEmpty == false {
                for dimension in lastDimension {
                    dimensionIndex += 1
                    
                    if dimension.key != "" {
                        if dimension.type == Dimension.generalType {
                            customDimensionItems.append(URLQueryItem(name: EventParams.customDimensionD + "\(dimensionIndex)", value: dimension.value))
                        } else if dimension.type == Dimension.factType {
                            customDimensionItems.append(URLQueryItem(name: EventParams.customDimensionF + "\(dimensionIndex)", value: String(dimension.numValue)))
                        }
                    }
                }
            }
        } else {
            // 동적 파라미터
            if !self.dimensions.isEmpty {
                customDimensionItems.append(URLQueryItem(name: EventParams.dynamicDimension, value: convertJsonStringWithDynamicCommonDimensions()))
            }
        }
        let eventsAsQueryItems = eventCommonItems + customDimensionItems
        let serializedEvents = eventsAsQueryItems.reduce(into: [String:String]()) {
            $0[$1.name] = $1.value
        }
        return serializedEvents.map{
            "\($0.key)≡\($0.value)"
        }.joined(separator: "∞")
    }
    
    private func serializeAppInfo() -> String {
        var eventCommonItems: [URLQueryItem] = []
        eventCommonItems.append(URLQueryItem(name: EventParams.eventPlatform, value: "2"))      // 웹뷰에서 보내온 로그 수집
        eventCommonItems.append(URLQueryItem(name: EventParams.deviceType, value: "app"))
        eventCommonItems.append(URLQueryItem(name: EventParams.appVersion, value: TagWorks.sharedInstance.appVersion ?? AppInfo.getBundleShortVersion()))
        eventCommonItems.append(URLQueryItem(name: EventParams.appName, value: TagWorks.sharedInstance.appName ?? AppInfo.getBundleName()))
        
        let eventsAsQueryItems = eventCommonItems
        let serializedEvents = eventsAsQueryItems.reduce(into: [String:String]()) {
            $0[$1.name] = $1.value
        }
        return serializedEvents.map{
            "\($0.key)≡\($0.value)"
        }.joined(separator: "∞")
    }
    
    private func serializeCommonDimensions() -> String {
        var customDimensionItems: [URLQueryItem] = []
        var dimensionIndex = 0
        var lastDimension: [Dimension] = []
        for dimension in self.dimensions {
            // 최대 인덱스를 가져옴
            if dimensionIndex <= dimension.index {
                dimensionIndex = dimension.index
            }
            
            if dimension.index != -1 {
                if dimension.type == Dimension.generalType {
                    customDimensionItems.append(URLQueryItem(name: EventParams.customDimensionD + "\(dimension.index)", value: dimension.value))
                } else if dimension.type == Dimension.factType {
                    customDimensionItems.append(URLQueryItem(name: EventParams.customDimensionF + "\(dimension.index)", value: String(dimension.numValue)))
                }
            } else {
                lastDimension.append(dimension)
            }
        }
        // 정적 디멘젼이 아닌 동적 디멘젼을 사용해서 추가한 경우 예외 처리
        if lastDimension.isEmpty == false {
            for dimension in lastDimension {
                dimensionIndex += 1
                
                if dimension.key != "" {
                    if dimension.type == Dimension.generalType {
                        customDimensionItems.append(URLQueryItem(name: EventParams.customDimensionD + "\(dimensionIndex)", value: dimension.value))
                    } else if dimension.type == Dimension.factType {
                        customDimensionItems.append(URLQueryItem(name: EventParams.customDimensionF + "\(dimensionIndex)", value: String(dimension.numValue)))
                    }
                }
            }
        }

        let eventsAsQueryItems = customDimensionItems
        let serializedEvents = eventsAsQueryItems.reduce(into: [String:String]()) {
            $0[$1.name] = $1.value
        }
        return serializedEvents.map{
            "\($0.key)≡\($0.value)"
        }.joined(separator: "∞")
    }
    
    private func serializeDynamicCommonDimensions() -> String {
        var customDimensionItems: [URLQueryItem] = []
        customDimensionItems.append(URLQueryItem(name: EventParams.dynamicDimension, value: convertJsonStringWithDynamicCommonDimensions()))
        
        let eventsAsQueryItems = customDimensionItems
        let serializedEvents = eventsAsQueryItems.reduce(into: [String:String]()) {
            $0[$1.name] = $1.value
        }
        return serializedEvents.map{
            "\($0.key)≡\($0.value)"
        }.joined(separator: "∞")
    }
    
    // 동적 파라미터 디멘젼을 jsonString으로 변환
    private func convertJsonStringWithDynamicCommonDimensions() -> String {
        var result: [String: Any] = [:]
        var stringDimensions: [String: String] = [:]
        var numericDimensions: [String: String] = [:]
        
        for dimension in self.dimensions {
            if dimension.key != "" {
                if dimension.type == Dimension.generalType {
                    stringDimensions[dimension.key] = dimension.value
                } else if dimension.type == Dimension.factType {
                    numericDimensions[dimension.key] = String(dimension.numValue)
                }
            }
            if dimension.index != -1 {
                if dimension.type == Dimension.generalType {
                    stringDimensions[String(dimension.index)] = dimension.value
                } else if dimension.type == Dimension.factType {
                    numericDimensions[String(dimension.index)] = String(dimension.numValue)
                }
            }
        }
        
        result[EventParams.dynamicDimensionString] = stringDimensions
        result[EventParams.dynamicDimensionNumeric] = numericDimensions
        
        do {
            // Dictionary Array를 JSON으로 변환
            let jsonData = try JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
            
            // JSON 데이터를 문자열로 변환하여 반환
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return(jsonString)
            }
        } catch {
            print("JSON 변환 오류: \(error)")
            return ""
        }
        return ""
    }
    
    
    /// URLQuery 파라미터를 저장하는 컬렉션입니다.
    var queryItems: [URLQueryItem] {
        get {
            if let e_c = eventCategory {
                // 웹뷰에서 호출이 되었을 경우, e_c 값 맨 뒤에 deviceType, AppVersion과 AppName을 덧붙인다.
                // App의 웹뷰에서 발송할때 deviceType을 전송하지 않는 경우, 하나의 이벤트로 인식하기 때문에 필히 추가
                let serializeDimensionString = TagWorks.sharedInstance.isUseDynamicParameter ? serializeDynamicCommonDimensions() : serializeCommonDimensions()
                let eventString = e_c + "∞" + serializeDimensionString + "∞" + serializeAppInfo()
                return [
                    URLQueryItem(name: URLQueryParams.siteId, value: siteId.urlEncodedForQuery),
                    URLQueryItem(name: URLQueryParams.userId, value: userId?.urlEncodedForQuery),
//                    URLQueryItem(name: URLQueryParams.url, value: url?.absoluteString.stringByAddingPercentEncoding),
//                    URLQueryItem(name: URLQueryParams.urlReferer, value: urlReferer?.absoluteString.stringByAddingPercentEncoding),
                    URLQueryItem(name: URLQueryParams.url, value: (url?.absoluteString.urlDecoded())?.urlEncodedForQueryWithEqual),
                    URLQueryItem(name: URLQueryParams.urlReferer, value: (urlReferer?.absoluteString.urlDecoded())?.urlEncodedForQueryWithEqual),
                    URLQueryItem(name: URLQueryParams.language, value: language?.addingPercentEncoding(withAllowedCharacters: .alphanumerics)?.urlEncodedForQuery),
                    URLQueryItem(name: URLQueryParams.clientDateTime, value: CommonUtil.Formatter.iso8601DateFormatter.string(from: clientDateTime)),
                    URLQueryItem(name: URLQueryParams.screenSize, value: String(format: "%1.0fx%1.0f", screenResolution.width, screenResolution.height)),
                    URLQueryItem(name: URLQueryParams.event, value: eventString.urlEncodedForQuery),
                ]
            }
            
            return [
                URLQueryItem(name: URLQueryParams.siteId, value: siteId.urlEncodedForQuery),
                URLQueryItem(name: URLQueryParams.userId, value: userId?.urlEncodedForQuery),
//                URLQueryItem(name: URLQueryParams.url, value: url?.absoluteString.stringByAddingPercentEncoding),
//                URLQueryItem(name: URLQueryParams.urlReferer, value: urlReferer?.absoluteString.stringByAddingPercentEncoding),
                URLQueryItem(name: URLQueryParams.url, value: (url?.absoluteString.urlDecoded())?.urlEncodedForQueryWithEqual),
                URLQueryItem(name: URLQueryParams.urlReferer, value: (urlReferer?.absoluteString.urlDecoded())?.urlEncodedForQueryWithEqual),
                URLQueryItem(name: URLQueryParams.language, value: language?.addingPercentEncoding(withAllowedCharacters: .alphanumerics)?.urlEncodedForQuery),
                URLQueryItem(name: URLQueryParams.clientDateTime, value: CommonUtil.Formatter.iso8601DateFormatter.string(from: clientDateTime)),
                URLQueryItem(name: URLQueryParams.screenSize, value: String(format: "%1.0fx%1.0f", screenResolution.width, screenResolution.height)),
                URLQueryItem(name: URLQueryParams.event, value: serializeEventString().urlEncodedForQuery)
            ]
        }
    }
    
    /// URLQuery 파라미터를 저장하는 컬렉션입니다.
    var queryItemsWithLocalQueue: [URLQueryItem] {
        get {
            if let e_c = eventCategory {
                // 웹뷰에서 호출이 되었을 경우, e_c 값 맨 뒤에 deviceType, AppVersion과 AppName을 덧붙인다.
                // App의 웹뷰에서 발송할때 deviceType을 전송하지 않는 경우, 하나의 이벤트로 인식하기 때문에 필히 추가
                let serializeDimensionString = TagWorks.sharedInstance.isUseDynamicParameter ? serializeDynamicCommonDimensions() : serializeCommonDimensions()
                let eventString = e_c + "∞" + serializeDimensionString + "∞" + serializeAppInfo() + "∞" + "obz_unsent≡1"
                return [
                    URLQueryItem(name: URLQueryParams.siteId, value: siteId.urlEncodedForQuery),
                    URLQueryItem(name: URLQueryParams.userId, value: userId?.urlEncodedForQuery),
                    URLQueryItem(name: URLQueryParams.url, value: (url?.absoluteString.urlDecoded())?.urlEncodedForQueryWithEqual),
                    URLQueryItem(name: URLQueryParams.urlReferer, value: (urlReferer?.absoluteString.urlDecoded())?.urlEncodedForQueryWithEqual),
                    URLQueryItem(name: URLQueryParams.language, value: language?.addingPercentEncoding(withAllowedCharacters: .alphanumerics)?.urlEncodedForQuery),
                    URLQueryItem(name: URLQueryParams.clientDateTime, value: CommonUtil.Formatter.iso8601DateFormatter.string(from: clientDateTime)),
                    URLQueryItem(name: URLQueryParams.screenSize, value: String(format: "%1.0fx%1.0f", screenResolution.width, screenResolution.height)),
                    URLQueryItem(name: URLQueryParams.event, value: eventString.urlEncodedForQuery),
                ]
            }
            
            return [
                URLQueryItem(name: URLQueryParams.siteId, value: siteId.urlEncodedForQuery),
                URLQueryItem(name: URLQueryParams.userId, value: userId?.urlEncodedForQuery),
                URLQueryItem(name: URLQueryParams.url, value: (url?.absoluteString.urlDecoded())?.urlEncodedForQueryWithEqual),
                URLQueryItem(name: URLQueryParams.urlReferer, value: (urlReferer?.absoluteString.urlDecoded())?.urlEncodedForQueryWithEqual),
                URLQueryItem(name: URLQueryParams.language, value: language?.addingPercentEncoding(withAllowedCharacters: .alphanumerics)?.urlEncodedForQuery),
                URLQueryItem(name: URLQueryParams.clientDateTime, value: CommonUtil.Formatter.iso8601DateFormatter.string(from: clientDateTime)),
                URLQueryItem(name: URLQueryParams.screenSize, value: String(format: "%1.0fx%1.0f", screenResolution.width, screenResolution.height)),
                URLQueryItem(name: URLQueryParams.event, value: (serializeEventString() + "∞" + "obz_unsent≡1").urlEncodedForQuery)
            ]
        }
    }
}
