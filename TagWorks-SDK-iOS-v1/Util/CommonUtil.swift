//
//  CommonUtil.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import Foundation

/// TagWorks SDK 내에서 사용되는 Util 클래스입니다.
final class CommonUtil {
    
    /// UTC 날짜 변환을 위한 Formatter 구조체 입니다.
    internal struct Formatter {
        
        /// iso8601Date 형태로 지정된 DateFormatter를 반환합니다.
        internal static let iso8601DateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            return formatter
        }()
    }
}

extension Locale {
    
    static var httpAcceptLanguage: String {
        var components: [String] = []
        for (index, languageCode) in preferredLanguages.enumerated() {
            let quality = 1.0 - (Double(index) * 0.1)
            components.append("\(languageCode);q=\(quality)")
            if quality <= 0.5 {
                break
            }
        }
        return components.joined(separator: ",")
    }
}

extension String {
    
    /// 일반적인 URL 인코딩 함수
    func URLEncodedString() -> String? {
        let escapedString = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return escapedString
    }
    func decodeUrl() -> String? {
        return self.removingPercentEncoding
    }
    
    /// 유입 경로 urlref 값으로 URL이 넘어가는데 URL 파라미터에 "&" 가 들어갈 수 있기 때문에 &도 인코딩이 필요하기에 허용 문자에서 예외시킴.
    /// '&' 를 제외한 URL 인코딩 사용 함수
    var stringByAddingPercentEncoding: String {
        // 허용할 문자열
        let unreserved = "!$\\()*+-./:;=?@_~"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        
        return self.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet) ?? self
    }
    
    static func queryStringFromParameters(parameters: Dictionary<String,String>) -> String? {
        if (parameters.count == 0)
        {
            return nil
        }
        var queryString : String? = nil
        for (key, value) in parameters {
            if let encodedKey = key.URLEncodedString() {
                if let encodedValue = value.URLEncodedString() {
                    if queryString == nil
                    {
                        queryString = "?"
                    }
                    else
                    {
                        queryString! += "&"
                    }
                    queryString! += encodedKey + "=" + encodedValue
                }
            }
        }
        return queryString
    }
}

