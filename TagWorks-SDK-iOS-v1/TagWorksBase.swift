//
//  TagWorksBase.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/16/24.
//

import Foundation
import WebKit

/// TagWorks에서 사용하는 UserDefault 관리 클래스입니다.
internal struct TagWorksBase {
    
    /// UserDefault 객체입니다.
    private let userDefaults: UserDefaults
    
    private let keychainStorage = KeychainStorage.sharedInstance
    private var isEnableKeychain = true
    
    /// UserDefault 인스턴스 초기화시 지정하는 식별자입니다.
    /// - Parameter suitName: UserDefault 식별자
    init(suitName: String?){
        self.userDefaults = UserDefaults(suiteName: suitName)!
        
        // 키체인에 저장할 용도로 사용
        let result = keychainStorage.migrate()
        if result == false {
            if #available(iOS 11.3, *) {
                let secCopyError = SecCopyErrorMessageString(keychainStorage.lastErrorStatus, nil)!
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Keychain migrate error: \(secCopyError)")
            }
        }
        
        // 기존에 userId 저장된 값이 있을 경우, 삭제 로직 추가 - 2025. 04.18 by Kevin
        userDefaults.removeObject(forKey: UserDefaultKey.userId)
        userDefaults.synchronize()
        
        // 테스트 용도로 visitorId를 삭제 (사용 후에는 절대로 주석처리 꼭 확인할 것!!!)
//        keychainStorage.remove()
        
        // Deeplink 정보를 서버에 전송하기 위해 미리 체크 해야할 부분 설정 - 중요!!!
        // 먼저 호출하지 않으면 디퍼드 딥링크 설치 시 처음 설치/재설치 여부 알 수 없음
        if keychainStorage.isCheckFirstInstall() == true {
            DeeplinkManager.sharedInstance.isFirstInstall = true
        } else {
            DeeplinkManager.sharedInstance.isFirstInstall = false
        }
    }
    
    /// 유저 식별자 (고객 식별자)를 저장 및 반환합니다.
    /// 기존에는 userId를 로컬에 저장 후 사용했지만, userId 셋팅을 통해 로그인 상태를 체크 용도로 사용하기에 로컬 파일에 저장하지 않도록 변경 - 장등수 상무, 이현진 차장 합의
    /// 2025. 04. 18 by Kevin
    //    public var userId: String? {
    //        get {
    //            return userDefaults.string(forKey: UserDefaultKey.userId)
    //        }
    //        set {
    //            userDefaults.setValue(newValue, forKey: UserDefaultKey.userId)
    //            userDefaults.synchronize()
    //        }
    //    }
    
    /// 방문자 식별자를 저장 및 반환합니다.
    /// 앱을 삭제해도 변하지 않도록 키체인을 이용하여 저장 및 반환하도록 변경 - by Kevin 2024.07.16
    internal var visitorId: String? {
        get {
            //            return userDefaults.string(forKey: UserDefaultKey.visitorId)
            return keychainStorage.findOrCreate()
        }
        set {
            //            userDefaults.setValue(newValue, forKey: UserDefaultKey.visitorId)
            //            userDefaults.synchronize()
            _ = keychainStorage.renew()
        }
    }
    
    /// 수집 허용 여부를 저장 및 반환합니다.
    public var optOut: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKey.optOut)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKey.optOut)
            userDefaults.synchronize()
        }
    }
    
    /// 앱이 비정상 종료를 대비해 Event를 저장 및 반환
    public var eventsLocalQueue: String? {
        get {
            return userDefaults.string(forKey: UserDefaultKey.eventsLocalQueue)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKey.eventsLocalQueue)
            userDefaults.synchronize()
        }
    }
    
    internal func clearLocalQueue() {
        userDefaults.removeObject(forKey: UserDefaultKey.eventsLocalQueue)
        userDefaults.synchronize()
    }
    
    // IBK 고객여정의 공통 디멘젼을 이용한 크래쉬 로그 저장
    internal var crashErrorLog: [[String: Any]]? {
        get {
            return userDefaults.array(forKey: UserDefaultKey.errorLog) as? [[String: Any]]
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKey.errorLog)
            userDefaults.synchronize()
        }
    }
    
    internal func clearCrashErrorLog() {
        userDefaults.removeObject(forKey: UserDefaultKey.errorLog)
        userDefaults.synchronize()
    }
    
    // TagWorks SDK 크래쉬 자동 탐지를 통한 크래쉬 로그 저장
    internal var crashErrorReport: [[String: Any]]? {
        get {
            return userDefaults.array(forKey: UserDefaultKey.errorReport) as? [[String: Any]]
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKey.errorReport)
            userDefaults.synchronize()
        }
    }
    
    internal func clearCrashErrorReport() {
        userDefaults.removeObject(forKey: UserDefaultKey.errorReport)
        userDefaults.synchronize()
    }
    
    // 앱 최초 실행 여부
    internal var isAppFirstLaunched: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKey.isAppFirstLaunch)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKey.isAppFirstLaunch)
            userDefaults.synchronize()
        }
    }
    
    internal var appInstallTime: String? {
        get {
            return userDefaults.string(forKey: UserDefaultKey.appInstallTime)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKey.appInstallTime)
            userDefaults.synchronize()
        }
    }
}
