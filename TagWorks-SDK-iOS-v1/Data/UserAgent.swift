//
//  UserAgent.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import Foundation

/// 수집 대상의 UserAgent 정보를 저장하는 구조체입니다.
public struct UserAgent {
    
    /// 어플리케이션 정보 저장 구조체
    let appInfo: AppInfo
    
    /// 디바이스 정보 저장 구조체
    let deviceInfo: DeviceInfo
    
    /// 수집 대상 UserAgent 정보를 반환합니다.
    var userAgentString: String {
        ["Darwin/\(deviceInfo.deviceDarwinVersion ?? "Unknown-Version") (\(deviceInfo.devicePlatform); \(deviceInfo.deviceOperatingSystem) \(deviceInfo.deviceOperatingSystemVersion))",
            "\(appInfo.bundleName ?? "Unknown-App")/\(appInfo.bundleShortVersion ?? "Unknown-Version")"
        ].joined(separator: " ")
    }
}
