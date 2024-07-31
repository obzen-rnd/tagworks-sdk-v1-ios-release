//
//  DefaultQueue.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import Foundation

/// 이벤트 구조체를 저장하는 Queue 인터페이스를 상속받는 구현체 클래스입니다.
public final class DefaultQueue: NSObject, Queue {
    
    /// 이벤트 구조체 컬렉션
    private var items = [Event]()
    
    /// queue의 사이즈를 반환합니다.
    public var size: Int {
        return items.count
    }
    
    /// queue에 이벤트 구조체 컬렉션을 저장합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - completion: 완료 CallBack
    public func enqueue(events: [Event], completion: (() -> Void)?) {
        items.append(contentsOf: events)
        completion?()
    }
    
    /// queue에서 이벤트 구조체를 제거합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - completion: 완료 CallBack
    public func remove(events: [Event], completion: @escaping () -> Void) {
        items = items.filter( {event in !events.contains(where: { target in target.uuid == event.uuid })})
        completion()
        print("Queue: remove() - remains(\(items)")
    }
    
    /// queue에서 이벤트 구조체를 반환합니다.
    /// - Parameters:
    ///   - limit: 이벤트 구조체의 최대수
    ///   - completion: 완료 CallBack
    public func first(limit: Int, completion: @escaping ([Event]) -> Void) {
        let amount = [limit, size].min()!
        let dequeueItems = Array(items[0..<amount])
        completion(dequeueItems)
    }
}
