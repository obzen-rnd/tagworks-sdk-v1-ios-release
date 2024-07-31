//
//  KeychainStorage.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by Digital on 7/25/24.
//

import Foundation
import Security

final public class KeychainStorage {
    
    // MARK: - 싱글톤 객체 생성 및 반환
    static public let sharedInstance = KeychainStorage()
    private init() {}
    
    private let account = "TagWorks/Account"
    private let service = Bundle.main.bundleIdentifier
    private var accessGroup: String?
    public var lastErrorStatus: OSStatus = noErr;
    
    // MARK: - Public Methods
    
    public func findOrCreate() -> String? {
        self.lastErrorStatus = noErr
        let UUIDString = find()
        if UUIDString != nil {
            return UUIDString
        }
        return create()
    }
    
    public func remove() -> Bool {
        self.lastErrorStatus = noErr
        let status = SecItemDelete(queryForRemove() as CFDictionary)
        return verifyStatusAndStoreLastError(status: status)
    }

    public func renew() -> String? {
        self.lastErrorStatus = noErr
        let result = remove()
        if result {
            return create()
        }
        return nil
    }

    public func migrate() -> Bool {
        self.lastErrorStatus = noErr
        let UUIDString = find()
        if UUIDString == nil {
            return false
        }
        
        let result = remove()
        if !result {
            return false
        }
        
        let status = SecItemAdd(queryForCreate(UUIDString: UUIDString!) as CFDictionary, nil)
        return verifyStatusAndStoreLastError(status: status)
    }

    
    // MARK: - Private Methods
    
    /// kSecClass: 키체인 아이템 클래스 타입
    /// kSecAttrService: 서비스 아이디 (앱 번들 아이디 사용)
    /// kSecAttrAccount: 저장할 아이템의 계정 이름
    /// kSecReturnAttributes: 속성 리턴 여부
    /// kSecReturnData: 데이터 리턴 여부
    private func queryForFind() -> Dictionary<CFString, Any> {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrService: service!,
            kSecMatchLimit: kSecMatchLimitOne,      // 하나의 아이템만 검색
            kSecReturnAttributes: true,
            kSecReturnData: true
        ]
    }
    
    private func queryForCreate(UUIDString: String) -> Dictionary<CFString, Any> {
        var items: Dictionary<CFString, Any> = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData: UUIDString.data(using: .utf8)!,
            kSecAttrDescription: "",
            kSecAttrService: service!,
            kSecAttrComment: ""]
        if (self.accessGroup != nil) && self.accessGroup!.count > 0 {
            items[kSecAttrAccessGroup] = self.accessGroup
        }
        return items
    }

    private func queryForRemove() -> Dictionary<CFString, Any> {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrService: service!,
        ]
    }
    
    private func verifyStatusAndStoreLastError(status: OSStatus) -> Bool {
        var isSuccess = (status == noErr)
        if isSuccess { return true }
        self.lastErrorStatus = status
        return false
    }
    
    private func create() -> String? {
        let UUIDString = UUID().uuidString
        var status: OSStatus = SecItemAdd(queryForCreate(UUIDString: UUIDString) as CFDictionary, nil)
        if verifyStatusAndStoreLastError(status: status) {
            return UUIDString
        }
        return nil
    }
    
    private func find() -> String? {
        // 검색한 아이템을 참조
        var result: CFTypeRef?
        
        // SecItemCopyMatching(아이템 검색 쿼리, 아이템 참조)
        let status = SecItemCopyMatching(queryForFind() as CFDictionary, &result)
        if !(verifyStatusAndStoreLastError(status: status)) {
            return nil
        }
        
        guard let existingItem = result as? [String: Any],
              let data = existingItem[kSecValueData as String] as? Data,
              let uuid = String(data: data, encoding: .utf8) else {
            return nil
        }
        return uuid
    }
    
}
