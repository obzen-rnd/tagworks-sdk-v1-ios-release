//
//  CrashLogManager.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 5/28/25.
//

import Foundation
import UIKit

// MARK: C 타입 전역 함수

// 백트레이스 수집
private func getBacktrace() -> String {
    let maxFrames = 128
    var symbols = [String]()
    
    // ⛳️ 올바른 타입: UnsafeMutablePointer<UnsafeMutableRawPointer?>
    let buffer = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: maxFrames)
    defer { buffer.deallocate() }

    let frameCount = backtrace(buffer, Int32(maxFrames))
    // 상위 15개의 프레임만 가져옴.
    let frameLimit = min(Int(frameCount), 15)
    if let frames = backtrace_symbols(buffer, frameCount) {
//        for i in 0..<Int(frameCount) {
        for i in 0..<Int(frameLimit) {
            if let symbol = frames[i] {
                symbols.append(String(cString: symbol))
            }
        }
        free(frames)
    }

    return symbols.joined(separator: "\n")
}

func saveCrashExceptipn(_ exception: NSException) {
    let stackTrace = "Reason: \(String(describing: exception.reason))\nStackTrace:\n\(exception.callStackSymbols.joined(separator: "\n"))"
    TagWorks.sharedInstance.saveCrashReport(errorType: "Exception", errorMessage: stackTrace)
}

func saveCrashSignal(_ signalValue: Int32) {
    let signalName: String
    switch signalValue {
        case SIGABRT:   signalName = "SIGABRT"
        case SIGSEGV:   signalName = "SIGSEGV"
        case SIGILL:    signalName = "SIGILL"
        case SIGFPE:    signalName = "SIGFPE"
        case SIGBUS:    signalName = "SIGBUS"
        case SIGPIPE:   signalName = "SIGPIPE"
        case SIGTRAP:   signalName = "SIGTRAP"
        default: signalName = "알 수 없는 신호 (\(signalValue))"
    }

    let reason = (signalValue == SIGTRAP) ? "FATALERROR" : signalName
    let stackTrace = "Reason: \(reason)\nStackTrace:\n\(getBacktrace())"
    TagWorks.sharedInstance.saveCrashReport(errorType: signalName, errorMessage: stackTrace)
    
    // 기본 동작으로 시그널 전달 (앱 종료)
    signal(signalValue, SIG_DFL)
    raise(signalValue)
}



// 앱 크래시 로그 수집 관리
public final class CrashLogManager {
    
    public static let sharedInstance = CrashLogManager()
    
    private init() {}

    // 앱 크래쉬 로그 핸들러 등록
    func setupGlobalSignalHandler() {
        
        // 예외 핸들러 등록 (Objective-C 에서 발생하는 오류)
        NSSetUncaughtExceptionHandler { exception in
            saveCrashExceptipn(exception)
        }
        
        // 주요 fatalError 핸들러 등록
        // Signal Abort - 프로세스가 자신을 강제로 종료할 때 발생(abort(), assert() 실패)하거나 예외 처리 미비로 fatalError() 발생 시
        signal(SIGABRT) { signal in saveCrashSignal(signal) }
        // Signal Segmentation Fault - 잘못된 메모리 접근 시 발생, 널 포인트 참조, 잘못된 주소 접근(배열 범위 초과), 스택 오버플로우
        signal(SIGSEGV) { signal in saveCrashSignal(signal) }
        // Signal Illegal Instruction - 잘못된 CPU 명령어를 실행하려고 할 때 발생, 잘못된 함수 포인터 호출
        signal(SIGILL) { signal in saveCrashSignal(signal) }
        // Signal Floating-Point Exception - 잘못된 수학 연산 수행 시 발생, 정수 나눗셈에서 0으로 나눔
        signal(SIGFPE) { signal in saveCrashSignal(signal) }
        // Signal Bus Error - 잘못된 메모리 접근인데, SIGSEGV와 달리 버스(하드웨어 수준) 문제로 판단되는 경우, 메모리 정렬 규칙 위반
        signal(SIGBUS) { signal in saveCrashSignal(signal) }
        // Signal Broken Pipe - 데이터를 쓰려고 한 파이프가 더 이상 존재하지 않을 때 발생, 소켓 통신 중 상대방이 연결을 끊었는데 계속 데이터를 보내려고 할 때
        signal(SIGPIPE) { signal in saveCrashSignal(signal) }
        // Signal Trap - 프로세스가 디버거에 의해 중단되거나 특정 디버깅 이벤트 발생했을 때 (POSIX 시스템에서 사용됨 - fatalerror() 나 out of index 에러 발생 시)
        signal(SIGTRAP) { signal in saveCrashSignal(signal) }
        
    }
    
    // 앱 크래시 발생 시 타입과 스택 트레이스 정보를 UserDefault에 저장
    func saveErrorStackTrace(errorType: String, errorMessage: String, isTagWorks: Bool = false) {
        guard TagWorks.sharedInstance.isInitialize() else { return }
        
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] saveErrorStackTrace! isTagWorks: \(isTagWorks)")
        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] saveErrorStackTrace! errorType: \(errorType)")
//        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] \(errorMessage)!!")
//        print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] \(String(describing: tagWorksBase?.crashErrorLog))!!")
        
        // 현재 KST 타임스탬프 가져오기
        let timestamp = CommonUtil.Formatter.getCurrentKSTimeString()
        // 에러 정보 셋팅
        let errorDict: [String: String] = [
            "errorType" : errorType,
            "errorData" : errorMessage,
            "timestamp" : timestamp ?? ""
        ]
        
        var errorArray: [[String: Any]] = []

        if isTagWorks {
            if let existErrorLog = TagWorks.sharedInstance.tagWorksBase?.crashErrorReport {
                errorArray = existErrorLog
            }
            errorArray.append(errorDict)
            
            TagWorks.sharedInstance.tagWorksBase?.crashErrorReport = errorArray
        } else {
            if let existErrorLog = TagWorks.sharedInstance.tagWorksBase?.crashErrorLog {
                errorArray = existErrorLog
            }
            errorArray.append(errorDict)
            
            TagWorks.sharedInstance.tagWorksBase?.crashErrorLog = errorArray
        }
    }
    

//    public func start() {
//        CrashLogStorage.redirectStderr()
//    }
//
//    public func checkAndSaveCrashIfNeeded() {
//        guard let log = CrashLogStorage.readLog(),
//              log.contains("Fatal error") || log.contains("SIG") else { return }
//
//        let formatted = CrashLogFormatter.format(log: log)
//        
//        // fatalerror 가 발생한 경우, 해당 크래쉬 로그를 저장 후 해당 로그파일 삭제
//        TagWorks.sharedInstance.saveCrashReport(errorType: "FatalError", errorMessage: formatted)
//        CrashLogStorage.clear()
//    }
}

// 로그 파일 저장소
enum CrashLogStorage {
    
//    private static let logPath = FileManager.default.temporaryDirectory
//        .appendingPathComponent("crash.log").path
    
    private static let logPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("crash_log.plist").path

    // stderr 스트림을 파일로 리디렉션
//    static func redirectStderr() {
//        fflush(stderr)      // 기존 로그 버퍼 비우기
//        freopen(logPath, "a+", stderr)
//    }

    static func readLog() -> String? {
        guard let data = FileManager.default.contents(atPath: logPath) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func clear() {
        try? FileManager.default.removeItem(atPath: logPath)
    }
}

enum CrashLogFormatter {
    
    static func format(log: String) -> String {
        let device = UIDevice.current
        let info = """
        Device: \(device.model)
        System: \(device.systemName) \(device.systemVersion)
        Timestamp: \(CommonUtil.Formatter.getCurrentKSTimeString()!)
        Log Timestamp: \(Date())
        --------------------------------
        \(log)
        """
        return info
    }
}
