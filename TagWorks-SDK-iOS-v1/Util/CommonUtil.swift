//
//  CommonUtil.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import UIKit
import Foundation
//import CryptoSwift

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
    
    public static func getSDKVersion() -> String? {
        // 현재 프레임워크의 번들을 가져옵니다.
        let frameworkBundle = Bundle(for: CommonUtil.self)
        
        // 버전 정보 가져오기
        if let version = frameworkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return version
        }
        return nil
    }
    
    // 화면 크기에 맞춰 비율을 적용하여 높이를 리턴하는 함수
    public static func calculateHeight(for size: CGSize) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width        // 화면 가로 크기
        let scaleFactor = screenWidth / size.width          // 화면 크기 대비 원본 크기의 가로 비율
        let calculatedHeight = size.height * scaleFactor    // 높이 계산
        
        return calculatedHeight
    }
    
    // 가로, 세로 비율을 고려하여 새로 계산된 세로 값을 리턴하는 함수
    static func calculateNewHeight(originalWidth: CGFloat, originalHeight: CGFloat, newWidth: CGFloat) -> CGFloat {
        // 가로, 세로 비율 계산
        let aspectRatio = originalHeight / originalWidth
        
        // 새 가로 값에 맞는 세로 값 계산
        let newHeight = newWidth * aspectRatio
        
        return newHeight
    }
    
    // 화면의 넓이에 맞춰 폰트 크기를 계산하는 함수
    static func getRatioFontSize(originWidth: CGFloat, originFontSize: CGFloat, viewWidth: CGFloat? = nil) -> CGFloat {
        let baseWidth: CGFloat = originWidth // 기준 넓이
        let baseFontSize: CGFloat = originFontSize // 기준 폰트 크기
        
        let currentWidth: CGFloat = viewWidth == nil ? UIScreen.main.bounds.width : viewWidth! // 현재 화면 넓이
        
        // 비율에 맞춰 폰트 크기 계산
        let fontSize = baseFontSize * (currentWidth / baseWidth)
        
        return fontSize
    }
    
    // 현재 날짜를 가져오는 함수
    static func getCurrentDateTime() -> Date {
        return Date()
    }
    
    static func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"  // 날짜 형식 설정
        return dateFormatter.string(from: date)
    }
    
    static func stringToDate(_ string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: string)
    }
    
    // 현재 시간에 설정한 딜레이 시간(초)를 더한 시간을 리턴
    static func addedDelaySeconds(seconds: Int) -> Date {
        let currentDate = Date() // 현재 날짜 및 시간
        let calendar = Calendar.current
        let addedSeconds = calendar.date(byAdding: .second, value: seconds, to: currentDate)
        return addedSeconds!
    }
    
    // 현재 시간에 설정한 딜레이 시간(일)를 더한 시간을 리턴
    static func addedDelayDays(days: Int) -> Date {
        let currentDate = Date() // 현재 날짜 및 시간
        let calendar = Calendar.current
        let addedSeconds = calendar.date(byAdding: .day, value: days, to: currentDate)
        return addedSeconds!
    }
    
    // 지정한 초 이상 경과 여부 체크
    static func isSecondsPassed(from time: Date, seconds: TimeInterval) -> Bool {
        let currentDate = Date() // 현재 날짜 및 시간
        let timeInterval = currentDate.timeIntervalSince(time) // 지정된 시간과 현재 시간의 차이 (초 단위)
        
        return timeInterval >= seconds // 지정 초 이상 경과했으면 true, 그렇지 않으면 false
    }
    
    // 오늘 날짜인지 여부 체크
    static func isDateToday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }
    
    // 두 날짜가 동일한 날인지, 아니면 다음 날인지 확인하는 함수
    static func isNextDay(from previousDate: Date, nextDays: Int) -> Bool {
        let currentDate = Date()            // 현재 날짜 및 시간
        let calendar = Calendar.current
        
        // 날짜가 같다면 (하루가 지나지 않았다면) false
        if calendar.isDate(previousDate, inSameDayAs: currentDate) {
            return false
        }
        
        // 날짜가 다르고, 하루 차이 나는 경우 (다음 날로 변경)
        if calendar.dateComponents([.day], from: previousDate, to: currentDate).day! > nextDays {
            return true
        }
        
        return false
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
    public func decodeUrl() -> String? {
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

public class AES256Util {
    //키값 32바이트: AES256(24bytes: AES192, 16bytes: AES128)
//    private static let SECRET_KEY = "01234567890123450123456789012345"
//    private static let IV = "0123456789012345"
    private static let SECRET_KEY = "ObzenTagworksSDKAes256SecretKeY1"
    private static let IV = SECRET_KEY[..<SECRET_KEY.index(SECRET_KEY.startIndex, offsetBy: 16)]
 
    static func encrypt(string: String) -> String {
        guard !string.isEmpty else { return "" }
        return try! getAESObject().encrypt(string.bytes).toBase64() ?? ""
    }
    
    static func encrypt(data: Data) -> String {
        guard !data.isEmpty else { return "" }
        return try! getAESObject().encrypt(data.bytes).toBase64() ?? ""
    }
 
    static public func decrypt(encoded: String) -> String {
        let datas = Data(base64Encoded: encoded)
 
        guard datas != nil else {
            return ""
        }
 
        let bytes = datas!.bytes
        let decode = try! getAESObject().decrypt(bytes)
 
        return String(bytes: decode, encoding: .utf8) ?? ""
    }
 
    private static func getAESObject() -> AES {
        let keyDecodes : Array<UInt8> = Array(SECRET_KEY.utf8)
        let ivDecodes : Array<UInt8> = Array(IV.utf8)
        let aesObject = try! AES(key: keyDecodes, blockMode: CBC(iv: ivDecodes), padding: .pkcs5)
 
        return aesObject
    }
}
