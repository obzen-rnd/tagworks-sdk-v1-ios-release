//
//  AppInfo.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/16/24.
//

import Foundation

/// 수집되는 어플리케이션의 식별 정보를 저장하는 구조체입니다.
public struct AppInfo {
    
    /// 앱 표기명
    public let bundleDisplayName: String?
    
    /// 앱 고유명
    public let bundleName: String?
    
    /// 앱 Identifier
    public let bundleIdentifier: String?
    
    /// 앱 Version
    public let bundleVersion: String?
    
    /// 앱 ShortVersion
    public let bundleShortVersion: String?
    
    public static func getApplicationInfo() -> AppInfo {
        return AppInfo(bundleDisplayName: getBundleDisplayName(),
                       bundleName: getBundleName(),
                       bundleIdentifier: getBundleIdentifier(),
                       bundleVersion: getBundleVersion(),
                       bundleShortVersion: getBundleShortVersion())
    }
}

extension AppInfo {
    
    /// 앱 표기명을 반환합니다.
    /// - Returns: 앱 표기명
    private static func getBundleDisplayName() -> String? {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    }
    
    /// 앱 고유명을 반환합니다.
    /// - Returns: 앱 고유명
    private static func getBundleName() -> String? {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String
    }
    
    /// 앱 Identifier를 반환합니다.
    /// - Returns: 앱 Identifier
    private static func getBundleIdentifier() -> String? {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
    }
    
    /// 앱 Version을 반환합니다.
    /// - Returns: 앱 Version
    private static func getBundleVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }
    
    /// 앱 ShortVersion을 반환합니다.
    /// - Returns: 앱 ShortVersion
    private static func getBundleShortVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
