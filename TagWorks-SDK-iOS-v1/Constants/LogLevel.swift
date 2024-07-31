//
//  LogLevel.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

/// 디버그 모드에서만 print() 출력되도록 설정..
func print(_ items: Any...) {
    #if DEBUG
        Swift.print(items[0])
    #endif
}

/// TagWorks Logger 의 로그 레벨을 열거합니다.
@objc public enum LogLevel: Int {
    case verbose    = 10
    case debug      = 20
    case info       = 30
    case warning    = 40
    case error      = 50
    
    var shortcut: String {
        switch self {
        case .error:    return "E"
        case .warning:  return "W"
        case .info:     return "I"
        case .debug:    return "D"
        case .verbose:  return "V"
        }
    }
}
