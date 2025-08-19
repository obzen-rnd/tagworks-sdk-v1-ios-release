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
    
    /// 로그 직렬화 인터페이스를 상속받는 클래스 객체입니다.
    private let serializer = EventSerializer()
    
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
        
        // 값 설정 여부에 따라 userDefault에 저장할지 결정
        if TagWorks.sharedInstance.localQueueEnabled {
            var jsonBody: Data
            do {
                jsonBody = try serializer.toJsonData(for: items, isLocalQueue: true)
                
                TagWorks.sharedInstance.tagWorksBase?.eventsLocalQueue = String(data: jsonBody, encoding: .utf8) ?? ""
                print("[🐹🐹🐹🐹] : \(TagWorks.sharedInstance.tagWorksBase?.eventsLocalQueue ?? "Nothing!!!")")
            } catch {
                completion?()
                return
            }
        }
        completion?()
    }
    
    public func enqueue(events: [Event], completion: @escaping (_ newSize: Int) -> Void) {
        items.append(contentsOf: events)
        
        // 값 설정 여부에 따라 userDefault에 저장할지 결정
        if TagWorks.sharedInstance.localQueueEnabled {
            var jsonBody: Data
            do {
                jsonBody = try serializer.toJsonData(for: items, isLocalQueue: true)
                
                TagWorks.sharedInstance.tagWorksBase?.eventsLocalQueue = String(data: jsonBody, encoding: .utf8) ?? ""
                print("[🐹🐹🐹🐹] : \(TagWorks.sharedInstance.tagWorksBase?.eventsLocalQueue ?? "Nothing!!!")")
            } catch {
                completion(items.count)
                return
            }
        }
        completion(items.count)
    }
    
    /// queue에서 이벤트 구조체를 제거합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - completion: 완료 CallBack
    public func remove(events: [Event], completion: @escaping () -> Void) {
        let beforeCount = items.count
        items = items.filter( {event in !events.contains(where: { target in target.uuid == event.uuid })})
        
        let removedCount = beforeCount - items.count
        TagWorks.log("Queue: remove() - removed[\(removedCount)] remains[\(items.count)]")
        
        completion()
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
