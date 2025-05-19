//
//  Serializer.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

/// 로그 발송을 위해 이벤트 구조체를 직렬화 하는 인터페이스입니다.
public protocol Serializer {
    
    /// 이벤트 구조체에 저장된 프로퍼티를 String 형태의 Map으로 반환합니다.
    /// - Parameter event: 이벤트 구조체
    /// - Returns: 이벤트 프로퍼티 Map
    func queryItems(for event: Event) -> [String: String]
    
    /// 이벤트 구조체에 저장된 프로퍼티를 Json 형태의 Data로 반환합니다.
    /// - Parameter events: 이벤트 구조체 컬렉션
    /// - Returns: Json Data
    func toJsonData(for events: [Event], isLocalQueue: Bool) throws -> Data
}
