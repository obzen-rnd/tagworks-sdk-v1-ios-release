//
//  DataBundle.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

/// 공용 EventKey String 정의
/// DataBundle에 값을 셋팅하기 위한 Key 값
/// Objective-C에서도 사용하기 위해 클래스로 생성
@objc extension DataBundle {
    /// Event 항목 정의
    /// Event Key
    static public let EVENT_TAG_NAME: String               = "OBZEN_EVENT_NAME"                 // pageView, click...
    static public let EVENT_TAG_PARAM_TITLE: String        = "EVENT_TAG_PARAM_TITLE"
    static public let EVENT_TAG_PARAM_PAGE_PATH: String    = "EVENT_TAG_PARAM_PAGE_PATH"
    static public let EVENT_TAG_PARAM_KEYWORD: String      = "EVENT_TAG_PARAM_KEYWORD"
    static public let EVENT_TAG_PARAM_CUSTOM_PATH: String  = "EVENT_TAG_PARAM_CUSTOM_PATH"      // 분석용(논리적인 그룹을 만들어 분석 용도로 사용 - 예를 들면 구매 페이지의 모든 하위 페이지를 '구매'로 묶어서 확인)
//  static public let EVENT_TAG_PARAM_DIMENSIONS: String   = "EVENT_TAG_PARAM_DIMENSIONS"
    static public let EVENT_TAG_PARAM_ERROR_MSG: String    = "EVENT_TAG_PARAM_ERROR_MSG"
}

/// 사용자 정의 이벤트 저장을 위한 클래스입니다.
/// Dimension은 서버에서 정의해 놓은 Map 형태의 테이블이 존재하기에 그에 따름.
@objc public final class DataBundle: NSObject, Codable {
    
    /// 데이터를 한번에 저장할 Dictionary Array
    internal var dataDictionary: [String: String] = [:]
    internal var eventDimensions: [Dimension] = []
    
    ///
    /// 초기화 함수
    /// 사용자 정의 기본 생성자입니다.
    @objc public override init() {
        super.init()
    }
    
    @objc public convenience init(_ bundle: DataBundle) {
        self.init()
        
        // 기존 번들 내용을 복사
        self.dataDictionary.forEach { bundle.dataDictionary[$0] = $1 }
        self.eventDimensions.append(contentsOf: bundle.eventDimensions)
    }
    
    ///
    /// 초기화 - End
    ///
    
    
    ///
    /// 파라미터 추가
    /// 이벤트에 필요한 파라미터 항목들을, Key, Value의 String 형태로 Dictionary에 추가
    ///
    @objc(putString:value:)
    public func putString(_ key: String, _ value: String) {
        dataDictionary[key] = value
    }
    
    /// 파라미터 제거
    /// 이벤트에 필요한 파라미터 항목들 중에 해당 키 항목을 제거
    @objc public func remove(forKey key: String) {
        dataDictionary.removeValue(forKey: key)
    }
    
    ///
    /// 이벤트에 필요한 Dimension 항목들을, Array에 추가
    /// 단, 추가하기 전 중복 항목 체크..
    ///
    @objc public func putDimensions(_ dimensions: [Dimension]) {
        // 중복 항목을 제거한 후, array 추가
        for dimension in dimensions {
            removeDimension(WithType: dimension.type, index: dimension.index)
        }
        eventDimensions.append(contentsOf: dimensions)
    }
    
    /// 이벤트 디멘전을 가져옵니다.
    /// - Parameters:
    ///  - WithType: 디멘전 type
    ///  - index: 디멘전 index
    @objc public func getDimension(WithType type: Int, index: Int) -> Dimension? {
        return self.eventDimensions.filter {$0.index == index && $0.type == type}.first
    }
    
    
//    /// 이벤트에 필요한 파라미터 항목들 중에 해당 키 항목을 제거
//    @objc public func delete(forKey key: String) {
//        if let index = dataDictionary.index(forKey: key) {
//            dataDictionary.remove(at: index)
//        }
//    }
    
    /// 해당 index의 Dimension을 삭제
    /// - Parameter index: 삭제할 디멘전 index
    @objc public func removeDimension(WithType type: Int, index: Int) {
        eventDimensions.removeAll(where: {$0.index == index && $0.type == type})
    }
        
//    @objc public func deleteDimension(index: Int) {
//        eventDimensions = eventDimensions.filter() { $0.index != index }
//    }

    /// 이벤트에 필요한 파라미터 항목들이 비어 있는지 체크
    @objc public func isParameterEmpty() -> Bool {
        if dataDictionary.isEmpty {
            return true
        }
        return false
    }
    
    /// 이벤트에 필요한 Dimension 항목들이 비어 있는지 체크
    @objc public func isDimensionEmpty() -> Bool {
        if eventDimensions.isEmpty {
            return true
        }
        return false
    }
    
    /// 이벤트에 필요한 파라미터 항목들의 갯수를 리턴
    @objc public func parameterCount() -> Int {
        return dataDictionary.count
    }
    
    /// 이벤트에 필요한 Dimension 항목들의 갯수를 리턴
    @objc public func dimensionCount() -> Int {
        return eventDimensions.count
    }
}
