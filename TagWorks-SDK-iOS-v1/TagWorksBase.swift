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
    public var visitorId: String? {
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
}
