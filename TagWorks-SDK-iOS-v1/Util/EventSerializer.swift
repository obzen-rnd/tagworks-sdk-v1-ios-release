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
        event.queryItems.reduce(into: [String:String]()) {
            $0[$1.name] = $1.value
        }
    }
    
    /// queue에서 이벤트 구조체를 반환합니다.
    /// - Parameter events: 이벤트 구조체 컬렉션
    /// - Returns: Json Data
    internal func toJsonData(for events: [Event]) throws -> Data {
        let eventsAsQueryItems: [[String: String]] = events.map { self.queryItems(for: $0) }
        let serializedEvents = eventsAsQueryItems.map { items in
            items.map {
                "\($0.key)=\($0.value)"
            }.joined(separator: "&")
        }
        print(serializedEvents)
        let body = ["requests": serializedEvents.map({ "?\($0)" })]
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

//        if visitorId != nil {
            eventCommonItems.append(URLQueryItem(name: EventParams.visitorId, value: visitorId))
//        }
        if pageTitle != nil {
            eventCommonItems.append(URLQueryItem(name: EventParams.pageTitle, value: pageTitle))
        }
        if searchKeyword != nil {
            eventCommonItems.append(URLQueryItem(name: EventParams.searchKeyword, value: searchKeyword))
        }
        if customUserPath != nil {
            eventCommonItems.append(URLQueryItem(name: EventParams.customUserPath, value: customUserPath))
        }

        eventCommonItems.append(URLQueryItem(name: EventParams.deviceType, value: "app"))

        let customDimensionItems = dimensions.map {
            if $0.type == Dimension.generalType {
                URLQueryItem(name: EventParams.customDimensionD + "\($0.index)", value: $0.value)
            } else {
                URLQueryItem(name: EventParams.customDimensionF + "\($0.index)", value: String($0.numValue))
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
    
    /// URLQuery 파라미터를 저장하는 컬렉션입니다.
    var queryItems: [URLQueryItem] {
        get {
            if let e_c = eventCategory {
                return [
                    URLQueryItem(name: URLQueryParams.siteId, value: siteId),
                    URLQueryItem(name: URLQueryParams.userId, value: userId),
                    URLQueryItem(name: URLQueryParams.url, value: url?.absoluteString),
                    URLQueryItem(name: URLQueryParams.urlReferer, value: urlReferer?.absoluteString),
                    URLQueryItem(name: URLQueryParams.language, value: language.addingPercentEncoding(withAllowedCharacters: .alphanumerics)),
                    URLQueryItem(name: URLQueryParams.screenSize, value: String(format: "%1.0fx%1.0f", screenResolution.width, screenResolution.height)),
                    URLQueryItem(name: URLQueryParams.event, value: e_c),
                    /// App의 웹뷰에서 발송할때 deviceType을 전송하지 않는 경우, 하나의 이벤트로 인식하기 때문에 필히 추가
                    URLQueryItem(name: EventParams.deviceType, value: "app")
                ]
            }
            
            return [
                URLQueryItem(name: URLQueryParams.siteId, value: siteId),
                // URLQueryItem(name: URLQueryParams.visitorId, value: visitorId),
                URLQueryItem(name: URLQueryParams.userId, value: userId),
                URLQueryItem(name: URLQueryParams.url, value: url?.absoluteString),
                URLQueryItem(name: URLQueryParams.urlReferer, value: urlReferer?.absoluteString),
                URLQueryItem(name: URLQueryParams.language, value: language.addingPercentEncoding(withAllowedCharacters: .alphanumerics)),
                URLQueryItem(name: URLQueryParams.clientDateTime, value: CommonUtil.Formatter.iso8601DateFormatter.string(from: clientDateTime)),
                URLQueryItem(name: URLQueryParams.screenSize, value: String(format: "%1.0fx%1.0f", screenResolution.width, screenResolution.height)),
                URLQueryItem(name: URLQueryParams.event, value: serializeEventString())
            ]
        }
    }
}

fileprivate extension CharacterSet {
    
    /// URLQuery 파라미터에 허용되는 특수문자를 반환합니다.
    static var urlQueryParameterAllowed: CharacterSet {
        return CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: ###"&/?;',+"!^()=@*$"###))
    }
}
