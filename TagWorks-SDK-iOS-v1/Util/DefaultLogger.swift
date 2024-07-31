//
//  DefaultLogger.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import Foundation

/// 런타임 로그 발생을 위한 Logger 인터페이스를 상속받는 구현체 클래스 입니다.
@objc public final class DefaultLogger: NSObject, Logger {
    
    /// 런타임 로그를 저장하는 Queue 컬렉션입니다.
    private let dispatchQueue = DispatchQueue(label: "DefaultLogger", qos: .background)
    
    /// 런타임 로거의 로그 레벨입니다.
    private let minLevel: LogLevel
    
    /// 런타임 로거 클래스의 기본 생성자입니다.
    /// - Parameter minLevel: 로그 레벨
    @objc public init(minLevel: LogLevel) {
        self.minLevel = minLevel
        super.init()
    }
    
    /// 런타임 로그를 입력받아 콘솔에 로그를 출력합니다.
    /// Protocol 구현부
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - level: 로그 레벨
    ///   - file: 로그 파일
    ///   - function: 로그 함수
    ///   - line: 로그 라인
    public func log(_ message: @autoclosure () -> String, with level: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue >= minLevel.rawValue else { return }
        let messageToPrint = message()
        dispatchQueue.async {
            print("TagWorks (\(function):\(line) [\(level.shortcut)] \(messageToPrint)")
        }
    }
}

/// Protocol에서 기본적으로 구현을 제공해주고 싶을 경우,  extension을 통해 제공.
extension Logger {
    
    /// verbose 로그를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - file: 로그 파일
    ///   - function: 로그 함수
    ///   - line: 로그 라인
    func verbose(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), with: .verbose, file: file, function: function, line: line)
    }
    
    /// debug 로그를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - file: 로그 파일
    ///   - function: 로그 함수
    ///   - line: 로그 라인
    func debug(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), with: .debug, file: file, function: function, line: line)
    }
    
    /// info 로그를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - file: 로그 파일
    ///   - function: 로그 함수
    ///   - line: 로그 라인
    func info(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), with: .info, file: file, function: function, line: line)
    }
    
    /// warning 로그를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - file: 로그 파일
    ///   - function: 로그 함수
    ///   - line: 로그 라인
    func warning(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), with: .warning, file: file, function: function, line: line)
    }
    
    /// error 로그를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - file: 로그 파일
    ///   - function: 로그 함수
    ///   - line: 로그 라인
    func error(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message(), with: .error, file: file, function: function, line: line)
    }
}

/// 런타임 로거를 비활성화 합니다.
public final class DisabledLogger: Logger {
    public func log(_ message: @autoclosure () -> String, with level: LogLevel, file: String = #file, function: String = #function, line: Int = #line) { }
}
