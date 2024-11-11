//
//  Event.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/22/24.
//

import Foundation

import CoreGraphics

/// 수집을 위한 로그 이벤트를 저장하는 구조체 입니다.
public struct Event: Codable {
    
    /// 이벤트 구조체 식별자
    public let uuid: UUID
    
    /// 수집 컨테이너 식별자
    let siteId: String
    
    /// 방문자 식별자
    let visitorId: String
    
    /// 유저 (고객) 식별자
    let userId: String?
    
    /// 이벤트 발생 url 주소
    let url: URL?
    
    /// 이전 이벤트 발생 url 주소
    let urlReferer: URL?
    
    /// 수집 대상자의 언어
    let language: String?
    
    /// 수집 대상자의 디바이스 스크린 사이즈
    var screenResolution: CGSize = DeviceInfo.getDeviceInfo().deviceScreenSize
    
    /// 이벤트 발생 시간
    let clientDateTime: Date
    
    /// 태그 이벤트 구분
    let eventType: String?
    
    /// 페이지 제목
    let pageTitle: String?
    
    /// 사용자 검색어
    let searchKeyword: String?
    
    /// 사용자 정의 경로
    let customUserPath: String?
    
    /// 사용자 정의 디멘전 컬렉션
    let dimensions: [Dimension]
    
    /// 사용자 에러 메세지
    let errorMsg: String?
    
    ///================================================
    /// 웹뷰로부터 받은 파라미터를 통해 이벤트를 생성하기 위한 변수들
    
    let eventCategory: String?      // e_c
}

extension Event {
    
    /// 로그 이벤트 저장을 위한 구조체의 기본 생성자입니다.
    /// - Parameters:
    ///   - tagWorks: TagWokrs 인스턴스
    ///   - url: 이벤트 발생 url 주소
    ///   - urlReferer: 이전 이벤트 발생 url 주소
    ///   - eventType: 태그 이벤트 구분
    ///   - pageTitle: 페이지 제목
    ///   - searchKeyword: 사용자 검색어
    ///   - customUserPath: 사용자 정의 경로
    ///   - dimensions: 사용자 정의 디멘전 컬렉션
    public init(tagWorks: TagWorks,
                url: URL? = nil,
                urlReferer: URL? = nil,
                eventType: String,
                pageTitle: String? = nil,
                searchKeyword: String? = nil,
                customUserPath: String? = nil,
                dimensions: [Dimension] = [],
                eventCategory: String? = nil,
                siteId: String? = nil,
                errorMsg: String? = nil) {
        self.uuid = UUID()
//        self.siteId = tagWorks.siteId ?? ""
        if let tagWorksSiteid = tagWorks.siteId {
            self.siteId = siteId ?? tagWorksSiteid
        } else {
            self.siteId = siteId ?? ""
        }
        self.visitorId = tagWorks.visitorId
        self.userId = tagWorks.userId
        self.url = url ?? tagWorks.currentContentUrlPath
        self.urlReferer = urlReferer
        self.language = DeviceInfo.getDeviceInfo().deviceLanguage
        self.clientDateTime = Date()
        self.eventType = eventType
        self.pageTitle = pageTitle
        self.searchKeyword = searchKeyword
        self.customUserPath = customUserPath
        self.dimensions = tagWorks.dimensions + dimensions
        self.eventCategory = eventCategory
        self.errorMsg = errorMsg
    }
}
