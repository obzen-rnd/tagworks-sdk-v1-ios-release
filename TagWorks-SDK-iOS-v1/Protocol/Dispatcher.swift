//
//  Dispatcher.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

/// 수집 이벤트 로그 발송 클래스의 인터페이스입니다.
public protocol Dispatcher {
    
    /// 수집 서버 url 주소입니다.
    var baseUrl: URL? { get }
    
    /// UserAgent 정보입니다.
    var userAgent: String? { get }
    
    /// 수집 이벤트 로그를 발송합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - success: http 송신 결과 성공
    ///   - failure: http 송신 결과 실패
    func send(events: [Event], success: @escaping ()->(), failure: @escaping (_ error: Error)->())
}
