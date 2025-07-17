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
    
    /// 디바이스 모델명
    public let deviceModelName: String
    
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
    
    /// 디바이스의 이름
    public let deviceName: String?
    
    
    /// 수집되는 디바이스의 정보 구조체를 반환합니다.
    /// - Returns: 디바이스 구조체
    /// 예시값 )
    /// iPhone14,8
    /// iOS
    /// 18.4.1
    /// (428.0, 926.0)
    /// (1284.0, 2778.0)
    /// Optional("24.4.0")
    /// Optional("ko")
    public static func getDeviceInfo() -> DeviceInfo {
        return DeviceInfo(devicePlatform: getDevicePlatform(),
                          deviceModelName: getDeviceModelName(),
                          deviceOperatingSystem: getDeviceOperatingSystem(),
                          deviceOperatingSystemVersion: getDeviceOperatingSystemVersion(),
                          deviceScreenSize: getDeviceScreenSize(),
                          deviceNativeScreenSize: getDeviceNativeScreenSize(),
                          deviceDarwinVersion: getDeviceDarwinVersion(),
//                          deviceLanguage: Locale.current.languageCode)
                          deviceLanguage: getDevicePreferredLanguage(),
                          deviceName: getDeviceName())
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
    
    // 기기식별자를 이용한 기기모델명 맵핑 후 전달
    private static func getDeviceModelName() -> String {
        let identifier = DeviceInfo.getDevicePlatform()
        
        switch identifier {
            case "iPhone17,5": return "iPhone 16e"
            case "iPhone17,2": return "iPhone 16 Pro Max"
            case "iPhone17,1": return "iPhone 16 Pro"
            case "iPhone17,4": return "iPhone 16 Plus"
            case "iPhone17,3": return "iPhone 16"
            case "iPhone16,2": return "iPhone 15 Pro Max"
            case "iPhone16,1": return "iPhone 15 Pro"
            case "iPhone15,5": return "iPhone 15 Plus"
            case "iPhone15,4": return "iPhone 15"
            case "iPhone15,3": return "iPhone 14 Pro Max"
            case "iPhone15,2": return "iPhone 14 Pro"
            case "iPhone14,8": return "iPhone 14 Plus"
            case "iPhone14,7": return "iPhone 14"
            case "iPhone14,6": return "iPhone SE (3rd)"
            case "iPhone14,3": return "iPhone 13 Pro Max"
            case "iPhone14,2": return "iPhone 13 Pro"
            case "iPhone14,5": return "iPhone 13"
            case "iPhone14,4": return "iPhone 13 mini"
            case "iPhone13,4": return "iPhone 12 Pro Max"
            case "iPhone13,3": return "iPhone 12 Pro"
            case "iPhone13,2": return "iPhone 12"
            case "iPhone13,1": return "iPhone 12 mini"
            case "iPhone12,8": return "iPhone SE (2nd)"
            case "iPhone12,5": return "iPhone 11 Pro Max"
            case "iPhone12,3": return "iPhone 11 Pro"
            case "iPhone12,1": return "iPhone 11"
            case "iPhone11,8": return "iPhone XR"
            case "iPhone11,6": return "iPhone XS Max (Global)"
            case "iPhone11,4": return "iPhone XS MAX"
            case "iPhone11,2": return "iPhone XS"
            case "iPhone10,6": return "iPhone X (GSM)"
            case "iPhone10,5": return "iPhone 8 Plus"
            case "iPhone10,4": return "iPhone 8"
            case "iPhone10,3": return "iPhone X (Global)"
            case "iPhone10,2": return "iPhone 8 Plus"
            case "iPhone10,1": return "iPhone 8"
            case "iPhone9,4":  return "iPhone 7 Plus"
            case "iPhone9,3":  return "iPhone 7"
            case "iPhone9,2":  return "iPhone 7 Plus"
            case "iPhone9,1":  return "iPhone 7"
            case "iPhone8,4":  return "iPhone SE (1st)"
            case "iPhone8,2":  return "iPhone 6S Plus"
            case "iPhone8,1":  return "iPhone 6S"
            case "iPhone7,2":  return "iPhone 6"
            case "iPhone7,1":  return "iPhone 6 Plus"
            case "iPhone6,2":  return "iPhone 5S (Global)"
            case "iPhone6,1":  return "iPhone 5S (GSM)"
            case "iPhone5,4":  return "iPhone 5c (Global))"
            case "iPhone5,3":  return "iPhone 5c (GSM)"
            case "iPhone5,2":  return "iPhone 5 (Global)"
            case "iPhone5,1":  return "iPhone 5 (GSM)"
            case "iPhone4,1":  return "iPhone 4S"
            case "iPhone3,3":  return "iPhone 4 (CDMA)"
            case "iPhone3,2":  return "iPhone 4 (GSM Rev A)"
            case "iPhone3,1":  return "iPhone 4"
            case "iPhone2,1":  return "iPhone 3GS"
            case "iPhone1,2":  return "iPhone 3G"
            case "iPhone1,1":  return "iPhone"
            default: return identifier
        }
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
    
    public static func getDeviceScreenResolution() -> CGSize {
        let screenSize = UIScreen.main.bounds.size          // 포인트 단위 (pt)
        let scale = UIScreen.main.scale                     // 스케일 (ex. 2.0, 3.0)
        return CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
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
    
    // 디바이스의 설정->일반->'언어 및 지역'에서 사용자가 설정한 우선순의 1순위의 언어 (실제로 폰에 적용된 언어)
    public static func getDevicePreferredLanguage() -> String? {
        return Locale.preferredLanguages.first?.components(separatedBy: "-").first
    }
    
    // 디바이스의 설정->일반->'언어 및 지역'에서 사용자가 설정한 지역과 언어 (예: ko-KR, en-US)
    public static func getDeviceResionLanguage() -> String? {
        return Locale.preferredLanguages.first
    }
    
    /// 사용자가 설정한 기기 이름을 반환합니다.
    public static func getDeviceName() -> String? {
        return UIDevice.current.name
    }
}
