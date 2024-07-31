//
//  Queue.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import Foundation

/// 이벤트 구조체를 저장하는 queue 컬렉션 인터페이스입니다.
public protocol Queue {
    
    /// queue의 사이즈를 반환합니다.
    var size: Int { get }
    
    /// queue에 이벤트 구조체 컬렉션을 저장합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - completion: 완료 CallBack
    mutating func enqueue(events: [Event], completion: (() -> Void)?)
    
    /// queue에서 이벤트 구조체를 제거합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - completion: 완료 CallBack
    mutating func remove(events: [Event], completion: @escaping () ->Void)
    
    /// queue에서 이벤트 구조체를 반환합니다.
    /// - Parameters:
    ///   - limit: 이벤트 구조체의 최대수
    ///   - completion: 완료 CallBack
    func first(limit: Int, completion: @escaping (_ items: [Event]) ->Void)
}

extension Queue {
    
    /// queue에 이벤트 구조체를 저장합니다. (add)
    /// - Parameters:
    ///   - event: 이벤트 구조체
    ///   - completion: 완료 CallBack
    mutating func enqueue(event: Event, completion: (() ->Void)? = nil) {
        enqueue(events: [event], completion: completion)
    }
}
