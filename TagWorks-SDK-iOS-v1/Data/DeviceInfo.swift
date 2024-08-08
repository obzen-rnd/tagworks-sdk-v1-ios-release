//
//  DeviceInfo.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/16/24.
//

import Foundation
import UIKit

/// 수집되는 디바이스의 정보를 저장하는 구조체입니다.
public struct DeviceInfo {
    
    /// 디바이스 플랫폼
    public let devicePlatform: String
    
    /// 디바이스 OS
    public let deviceOperatingSystem: String
    
    /// 디바이스 OS Version
    public let deviceOperatingSystemVersion: String
    
    /// 디바이스 스크린 사이즈 포인트
    public let deviceScreenSize: CGSize
    
    /// 디바이스 스크린 사이즈 픽셀
    public let deviceNativeScreenSize: CGSize
    
    /// 디바이스 OS 커널 Version
    public let deviceDarwinVersion: String?
    
    /// 다바이스 언어
    public let deviceLanguage: String?
    
    
    /// 수집되는 디바이스의 정보 구조체를 반환합니다.
    /// - Returns: 디바이스 구조체
    public static func getDeviceInfo() -> DeviceInfo {
        return DeviceInfo(devicePlatform: getDevicePlatform(),
                          deviceOperatingSystem: getDeviceOperatingSystem(),
                          deviceOperatingSystemVersion: getDeviceOperatingSystemVersion(),
                          deviceScreenSize: getDeviceScreenSize(),
                          deviceNativeScreenSize: getDeviceNativeScreenSize(),
                          deviceDarwinVersion: getDeviceDarwinVersion(),
                          deviceLanguage: Locale.current.languageCode)
    }
}

extension DeviceInfo {
    
    /// 디바이스 플랫폼 정보를 반환합니다.
    /// - Returns: 디바이스 플랫폼
    private static func getDevicePlatform() -> String {
        #if targetEnvironment(simulator)
            return ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "x86_64"
        #else
            var size = 0
            sysctlbyname("hw.machine", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0,  count: Int(size))
            sysctlbyname("hw.machine", &machine, &size, nil, 0)
            return String(cString: machine)
        #endif
    }
    
    /// 디바이스 OS를 반환합니다.
    /// - Returns: 디바이스 OS
    private static func getDeviceOperatingSystem() -> String {
        return "iOS"
    }
    
    /// 디바이스 OS Version을 반환합니다.
    /// - Returns: 디바이스 OS Version
    private static func getDeviceOperatingSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    /// 디바이스 스크린 사이즈를 반환합니다.
    /// - Returns: 디바이스 스크린 사이즈
    private static func getDeviceScreenSize() -> CGSize {
        return UIScreen.main.bounds.size
    }
    
    /// 디바이스 화면 픽셀 사이즈를 반환합니다.
    /// - Returns: 디바이스 화면 픽셀 사이즈
    private static func getDeviceNativeScreenSize() -> CGSize {
        return UIScreen.main.nativeBounds.size
    }
    
    /// 디바이스 OS 커널 Version을 반환합니다.
    /// - Returns: 디바이스 OS 커널 Version
    private static func getDeviceDarwinVersion() -> String? {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters)
    }
}
