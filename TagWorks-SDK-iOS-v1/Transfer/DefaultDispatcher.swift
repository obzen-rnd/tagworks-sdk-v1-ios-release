//
//  DefaultDispatcher.swift
//  TagWorks-iOS-v1
//
//  Created by Digital on 7/17/24.
//

import Foundation

/// 로그 송신을 위한 Dispatcher 인터페이스의 구현 클래스입니다.
public final class DefaultDispatcher: Dispatcher {
    
    /// 로그 직렬화 인터페이스를 상속받는 클래스 객체입니다.
    private let serializer: Serializer
    
    /// Http Request 타임아웃을 지정합니다.
    /// Maximun 1분을 기준으로 설정.
    private let timeOut: TimeInterval
    
    /// Http Request 세션 객체입니다.
    private let session: URLSession
    
    /// TagWorks 수집 서버 주소입니다.
    public let baseUrl: URL
    
    /// 수집 대상자의 UserAgent 정보입니다.
    public private(set) var userAgent: String?
    
    /// 기본 Dispatcher 클래스의 생성자입니다.
    /// - Parameters:
    ///   - serializer: 직렬화 인터페이스 상속 클래스
    ///   - timeOut: Http Request 타임아웃
    ///   - baseUrl: TagWorks 수집 서버 주소
    ///   - userAgent: UserAgent 정보
    public init(serializer: Serializer, timeOut: TimeInterval = 5.0, baseUrl: URL, userAgent: String? = nil) {
        self.serializer = serializer
        var tOut = timeOut
        if tOut <= 3.0 { tOut = 3.0 }
        else if tOut >= 60.0 { tOut = 60.0 }
        self.timeOut = tOut
        self.session = URLSession.shared
        self.baseUrl = baseUrl
        self.userAgent = userAgent ?? UserAgent(appInfo: AppInfo.getApplicationInfo(), deviceInfo: DeviceInfo.getDeviceInfo()).userAgentString
    }
    
    /// Http Request객체를 생성하여 반환합니다.
    /// - Parameters:
    ///   - baseURL: TagWorks 수집 서버 주소
    ///   - method: Http Request 메소드
    ///   - contentType: Http Request 컨텐츠 타입
    ///   - body: Http Request Body
    /// - Returns: Http Request 객체
    private func buildRequest(baseURL: URL, method: String, contentType: String? = nil, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: baseURL, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: timeOut)
        request.httpMethod = method
        body.map { request.httpBody = $0 }
        contentType.map { request.setValue($0, forHTTPHeaderField: "Content-Type") }
        userAgent.map { request.setValue($0, forHTTPHeaderField: "User-Agent") }
        return request
    }
    
    /// Http Request를 발송합니다.
    /// - Parameters:
    ///   - request: Http Request 객체
    ///   - success: http 송신 결과 성공
    ///   - failure: http 송신 결과 실패
    private func send(request: URLRequest, success: @escaping ()->(), failure: @escaping (_ error: Error)->()) {
        let task = session.dataTask(with: request) { data, response, error in
            
            print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Response: \(data as Any), \(response.map(\.url) as Any), Error - \(error as Any)")
            if let httpResponse = response as? HTTPURLResponse {
                print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] statusCode: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
        task.resume()
    }
    
    /// 이벤트 수집 정보를 직렬화 하여 Http Request로 생성합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - success: http 송신 결과 성공
    ///   - failure: http 송신 결과 실패
    public func send(events: [Event], success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        var jsonBody: Data
        do {
            jsonBody = try serializer.toJsonData(for: events)
            print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] Json Body: \(String(data:jsonBody, encoding: .utf8) ?? "")")
            // 취약점 발견으로 인한 암호화 적용
            // ##@ 를 붙이는 이유: 해당 패킷은 AES로 암호화 되어 있다는 표시
            let aesJsonBody: String = "##@" + AES256Util.encrypt(data: jsonBody)
            print("💁‍♂️[TagWorks v\(CommonUtil.getSDKVersion()!)] send Json AES Body: \(aesJsonBody)")
            
            jsonBody = aesJsonBody.data(using: .utf8)!
            
        } catch  {
            failure(error)
            return
        }
        let request = buildRequest(baseURL: baseUrl, method: "POST", contentType: "application/json; charset=utf-8", body: jsonBody)
        send(request: request, success: success, failure: failure)
    }
}
