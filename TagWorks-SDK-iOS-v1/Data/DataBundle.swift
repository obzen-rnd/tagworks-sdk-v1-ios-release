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
extension DataBundle {
    /// Event 항목 정의
    /// Event Key
    @objc static public let EVENT_TAG_NAME: String               = "OBZEN_EVENT_NAME"                 // pageView, click...
    @objc static public let EVENT_TAG_PARAM_TITLE: String        = "EVENT_TAG_PARAM_TITLE"
    @objc static public let EVENT_TAG_PARAM_PAGE_PATH: String    = "EVENT_TAG_PARAM_PAGE_PATH"
    @objc static public let EVENT_TAG_PARAM_KEYWORD: String      = "EVENT_TAG_PARAM_KEYWORD"
    @objc static public let EVENT_TAG_PARAM_CUSTOM_PATH: String  = "EVENT_TAG_PARAM_CUSTOM_PATH"      // 분석용(논리적인 그룹을 만들어 분석 용도로 사용 - 예를 들면 구매 페이지의 모든 하위 페이지를 '구매'로 묶어서 확인)
    @objc static public let EVENT_TAG_PARAM_ERROR_MSG: String    = "EVENT_TAG_PARAM_ERROR_MSG"
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
        for (key, value) in bundle.dataDictionary {
            self.dataDictionary[key] = value
        }
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
    

    /// 이벤트에 필요한 파라미터 항목들이 비어 있는지 체크
    @objc public func isParameterEmpty() -> Bool {
        return dataDictionary.isEmpty
    }
    
    /// 이벤트에 필요한 Dimension 항목들이 비어 있는지 체크
    @objc public func isDimensionEmpty() -> Bool {
        return eventDimensions.isEmpty
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

// MARK: - 개별 디멘전

extension DataBundle {
    
    // Dimension 중복 제거 유틸
    private func replaceDimension(in list: inout [Dimension], with newDimension: Dimension) {
        list.removeAll { $0 == newDimension }
        list.append(newDimension)
    }
    
    /*
        Index를 기반으로 디멘젼을 추가하는 방식
        - 동적 파라미터를 사용 시 해당 메소드는 사용하면 안됨!!
    */
    
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
    
    /// 수집 로그의 개별 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameter dimension: 추가할 디멘전 객체
    @objc public func putDimension(dimension: Dimension){
        removeDimension(WithType: dimension.type, index: dimension.index)
        self.eventDimensions.append(dimension)
    }
    
    @objc public func putDimension(_ dimension: Dimension){
        removeDimension(WithType: dimension.type, index: dimension.index)
        self.eventDimensions.append(dimension)
    }
    
    /// 수집 로그의 개별 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - index: 추가할 디멘전 index
    ///   - stringValue: 추가할 디멘전 value (d - String 타입)
    @objc public func putDimension(index: Int, stringValue: String) {
//        putDimension(dimension: Dimension(index: index, stringValue: stringValue))
        let dimension = Dimension(index: index, stringValue: stringValue)
        replaceDimension(in: &eventDimensions, with: dimension)
    }
    
    @objc public func putDimension(index: Int, value: String) {
//        putDimension(dimension: Dimension(index: index, value: value))
        let dimension = Dimension(index: index, value: value)
        replaceDimension(in: &eventDimensions, with: dimension)
    }
    
    /// 수집 로그의 개별 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - index: 추가할 디멘전 index
    ///   - numValue: 추가할 디멘전 value (f - Double 타입)
    @objc public func putDimension(index: Int, numValue: Double) {
//        putDimension(dimension: Dimension(index: index, numValue: numValue))
        let dimension = Dimension(index: index, numValue: numValue)
        replaceDimension(in: &eventDimensions, with: dimension)
    }
    
    /// 이벤트 디멘전을 가져옵니다.
    /// - Parameters:
    ///  - WithType: 디멘전 type
    ///  - index: 디멘전 index
    @objc public func getDimension(WithType type: Int, index: Int) -> Dimension? {
        return self.eventDimensions.filter {$0.index == index && $0.type == type}.first
    }
    
    @objc public func getDimensions() -> [Dimension] {
        return self.eventDimensions
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
        eventDimensions.removeAll(where: { $0.index == index && $0.type == type })
    }
    
    @objc public func removeDimensionWithArrayIndex(_ index: Int) {
        // IndexOutOfRange Crash 방지
        if eventDimensions.indices.contains(index) {
            eventDimensions.remove(at: index)
        }
    }
        
    @objc public func removeAllDimension() {
        eventDimensions.removeAll()
    }
    
    
    /*
        동적 파라미터(키값을 스트링으로 가지는)를 기반으로 디멘젼을 추가하는 방식
        - Index 파라미터를 사용 시 해당 메소드는 사용하면 안됨!!
    */
    
    ///
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameter dimensions: 추가할 디멘전 배열 객체
    ///
    @objc public func putDynamicDimension(dimensions: [Dimension]) {
        // 중복 항목을 제거한 후, array 추가
        for dimension in dimensions {
            removeDynamicDimension(key: dimension.key)
        }
        self.eventDimensions.append(contentsOf: dimensions)
    }
    
    @objc public func putDynamicDimensions(_ dimensions: [Dimension]) {
        // 중복 항목을 제거한 후, array 추가
        for dimension in dimensions {
            removeDynamicDimension(key: dimension.key)
        }
        self.eventDimensions.append(contentsOf: dimensions)
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameter dimension: 추가할 디멘전 객체
    @objc public func putDynamicDimension(dimension: Dimension){
        removeDynamicDimension(key: dimension.key)
        self.eventDimensions.append(dimension)
    }
    
    @objc public func putDynamicDimension(_ dimension: Dimension){
        removeDynamicDimension(key: dimension.key)
        self.eventDimensions.append(dimension)
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - index: 추가할 디멘전 index
    ///   - stringValue: 추가할 디멘전 value (d - String 타입)
    @objc public func putDynamicDimension(key: String, stringValue: String) {
        putDynamicDimension(dimension: Dimension(key: key, value: stringValue))
    }
    
    @objc public func putDynamicDimension(key: String, value: String) {
        putDynamicDimension(dimension: Dimension(key: key, value: value))
    }
    
    /// 수집 로그의 공용 디멘전을 지정합니다.
    /// * 이미 동일한 인덱스에 지정된 디멘전이 있는 경우 삭제하고 저장됩니다.
    /// - Parameters:
    ///   - index: 추가할 디멘전 index
    ///   - numValue: 추가할 디멘전 value (f - Double 타입)
    @objc public func putDynamicDimension(key: String, numValue: Double) {
        putDynamicDimension(dimension: Dimension(key: key, numValue: numValue))
    }
    
    /// 수집 로그의 공용 디멘전을 제거합니다.
    /// - Parameters:
    ///  - WithType: 디멘전 type
    ///  - index: 디멘전 index
    @objc public func removeDynamicDimension(key: String) {
        self.eventDimensions.removeAll(where: {$0.key == key})
    }
    
    @objc public func removeDynamicDimensionWithArrayIndex(_ index: Int) {
        self.eventDimensions.remove(at: index)
    }
    
    @objc public func removeAllDynamicDimension() {
        self.eventDimensions.removeAll()
    }
    
    /// 수집 로그의 공용 디멘전을 가져옵니다.
    /// - Parameters:
    ///  - WithType: 디멘전 type
    ///  - index: 디멘전 index
    @objc public func getDynamicDimension(key: String) -> Dimension? {
        return self.eventDimensions.filter {$0.key == key}.first
    }
    
    @objc public func getDynamicDimensions() -> [Dimension] {
        return self.eventDimensions
    }
}
