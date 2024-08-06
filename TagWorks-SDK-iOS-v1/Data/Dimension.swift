//
//  Dimension.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

/// 사용자 정의 디멘전 저장을 위한 클래스입니다.
/// Dimension은 서버에서 정의해 놓은 Map 형태의 테이블이 존재하기에 그에 따름.
public final class Dimension: NSObject, Codable {
    
    /// 사용자 정의 디멘전의 index
    let index: Int
    
    /// 사용자 정의 디멘전의 value
    let value: String
    
    /// fact
    let numValue: Double
    
    /// type
    var type: Int = generalType
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.index = try container.decode(Int.self, forKey: .index)
        self.value = try container.decode(String.self, forKey: .value)
        self.numValue = try container.decode(Double.self, forKey: .numValue)
        self.type = try container.decode(Int.self, forKey: .type)
    }

    /// 사용자 정의 디멘전의 기본 생성자입니다.
    /// - Parameters:
    ///   - type: 사용자 정의 디멘전의 Type (general, fact)
    ///   - index: 사용자 정의 디멘전의 index
    ///   - numValue: 사용자 정의 디멘전의 fact value
    ///   - stringValue: 사용자 정의 디멘전의 string value
    @objc public init(WithType type: Int = generalType, index: Int, stringValue: String, numValue: Double = 0) {
        self.type = type
        self.index = index
        self.numValue = numValue
        self.value = stringValue
        super.init()
    }
    
    @objc public init(index: Int, stringValue: String) {
        self.type = Dimension.generalType
        self.index = index
        self.numValue = 0
        self.value = stringValue
        super.init()
    }
    
    @objc public init(index: Int, numValue: Double = 0) {
        self.type = Dimension.factType
        self.index = index
        self.numValue = numValue
        self.value = ""
        super.init()
    }
    
//    @objc public init(index: Int, value: String){
//        self.index = index
//        self.value = value
//    }
}

extension Dimension {
    
    /// 입력받는 Dimension의 Type을 정의
    /// Codable Protocol을 준수하기 위해 static 일반 변수로 정의 후 사용토록 함.
    static public let generalType: Int  = 1
    static public let factType: Int     = 2
    
}
