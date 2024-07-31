//
//  Logger.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import Foundation

/// Logger 클래스의 인터페이스입니다.
@objc public protocol Logger {
    func log(_ message: @autoclosure () -> String, with level: LogLevel, file: String, function: String, line: Int)
}
