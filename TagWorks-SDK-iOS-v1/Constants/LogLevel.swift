//
//  LogLevel.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

/// 디버그 모드에서만 print() 출력되도록 설정하려 했으나 고객사 이슈 발생 시 대응이 어려워 플래그 설정
//func print(_ items: Any...) {
//    #if DEBUG
//        Swift.print(items[0])
//    
//        // 2️⃣ NotificationCenter를 통해 ViewController로 전달
//        NotificationCenter.default.post(name: .logUpdated, object: items[0])
//    #else
//        if TagWorks.sharedInstance.isDebugLogPrint {
//            Swift.print(items[0])
//        }
//    #endif
//}

// 📌 전역 print() 재정의
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let message = items.map { "\($0)" }.joined(separator: separator) + terminator
#if DEBUG
    // 1️⃣ 기존 print() 기능 유지 (Debug Console 출력)
    Swift.print(message, terminator: "")
    
    // 2️⃣ NotificationCenter를 통해 ViewController로 전달
    // 🔹 비동기 처리하여 성능 최적화
    if TagWorks.sharedInstance.isDebugLogPost {
        DispatchQueue.global(qos: .background).async {
            NotificationCenter.default.post(name: .logUpdated, object: message)
        }
    }
#else
    if TagWorks.sharedInstance.isDebugLogPrint {
        // 1️⃣ 기존 print() 기능 유지 (Debug Console 출력)
        Swift.print(message, terminator: "")
        
        // 2️⃣ NotificationCenter를 통해 ViewController로 전달
        // 🔹 비동기 처리하여 성능 최적화
        if TagWorks.sharedInstance.isDebugLogPost {
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .logUpdated, object: message)
            }
        }
    }
#endif
}

// 해당 함수를 호출한 함수의 정보를 출력하는 메소드
func debugPrint(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
    let log = "💥 Debug: \(message)\n📄 File: \(file)\n🔢 Line: \(line)\n🔧 Function: \(function)\n"
    print(log)
}

// 해당 함수를 호출한 함수의 정보를 가져오는 메소드
func logCrashContext(_ message: String, file: String = #file, line: Int = #line, function: String = #function) -> String {
    let log = "💥 Crash Context: \(message)\n📄 File: \(file)\n🔢 Line: \(line)\n🔧 Function: \(function)\n"
    return log
}


// 📌 로그 업데이트용 Notification 이름 정의
extension Notification.Name {
    static public let logUpdated = Notification.Name("logUpdated")
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
