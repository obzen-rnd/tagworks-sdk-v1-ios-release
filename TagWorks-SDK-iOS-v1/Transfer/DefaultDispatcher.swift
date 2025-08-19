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
    public let baseUrl: URL?
    
    /// 수집 대상자의 UserAgent 정보입니다.
    /// 외부에서 읽을 수는 있지만, 수정은 해당 클래스 내에서만 가능
//    public private(set) var userAgent: String?
    public var userAgent: String?
    
    /// 기본 Dispatcher 클래스의 생성자입니다.
    /// - Parameters:
    ///   - serializer: 직렬화 인터페이스 상속 클래스
    ///   - timeOut: Http Request 타임아웃
    ///   - baseUrl: TagWorks 수집 서버 주소
    ///   - userAgent: UserAgent 정보
    public init(serializer: Serializer, timeOut: TimeInterval = 5.0, baseUrl: URL, userAgent: String? = nil) {
        self.serializer = serializer
        let tOut = min(max(timeOut, 3.0), 60.0)         // timeOut 값: 최소 - 3초, 최대 - 60초
        self.timeOut = tOut
        self.session = URLSession.shared
        self.baseUrl = baseUrl
        // userAgent를 설정해도 아카이브에서는 기본 정보만 사용하기에 필요가 없다 판단해 파라미터로 설정하는 기능 제거.. - 2025.07.10 by Kevin
        // self.userAgent = (userAgent == nil || userAgent == "") ? UserAgent(appInfo: AppInfo.getApplicationInfo(), deviceInfo: DeviceInfo.getDeviceInfo()).userAgentString : userAgent
        if let ua = userAgent, !ua.isEmpty {
            self.userAgent = ua
        } else {
            self.userAgent = UserAgent(appInfo: AppInfo.getApplicationInfo(), deviceInfo: DeviceInfo.getDeviceInfo()).userAgentString
        }
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
            TagWorks.log("📡 Response URL: \(response?.url?.absoluteString ?? "No URL")")
            TagWorks.log("❌ Error: \(error?.localizedDescription ?? "nil")")
            
            if let error = error {
                failure(error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let unknownResponseError = NSError(
                    domain: "TagWorks.NetworkError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown network response."]
                )
                failure(unknownResponseError)
                return
            }
            
            TagWorks.log("📊 statusCode: \(httpResponse.statusCode)")
            
            if (200 ..< 300) ~= httpResponse.statusCode {
                success()
            } else {
                // ❗️여기: 상태코드가 실패일 때, Error를 생성해서 넘겨야 함
                let statusError = NSError(
                    domain: "TagWorks.NetworkError",
                    code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    ]
                )
                failure(statusError)
            }
        }
        task.resume()
    }
    
    /// 이벤트 수집 정보를 직렬화 하여 Http Request로 생성합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - success: http 송신 결과 성공
    ///   - failure: http 송신 결과 실패
    public func send(events: [Event], success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        do {
            let jsonData = try self.serializer.toJsonData(for: events, isLocalQueue: false)
            TagWorks.log("Json decoded Body: \(String(data: jsonData, encoding: .utf8)?.urlDecoded() ?? "")")
//            tagWorksPrint("Json Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            
            sendEncryptedJsonBody(jsonData, success: success, failure: failure)
        } catch {
            failure(error)
        }
    }
    
    /// 로컬 큐에 저장된 직렬화 이벤트 수집 정보를 Http Request로 생성합니다.
    /// - Parameters:
    ///   - events: 이벤트 구조체 컬렉션
    ///   - success: http 송신 결과 성공
    ///   - failure: http 송신 결과 실패
    public func send(localQueueEvents: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        guard let jsonData = localQueueEvents.data(using: .utf8) else {
            failure(NSError(domain: "TagWorks.LocalQueueError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid local queue JSON"]))
            return
        }
        TagWorks.log("Json decoded Body: \(String(data: jsonData, encoding: .utf8)?.urlDecoded() ?? "")")
//        tagWorksPrint("Json Body: \(jsonData)")
        
        sendEncryptedJsonBody(jsonData, success: success, failure: failure)
    }
    
    // MARK: Private Func
    
    private func sendEncryptedJsonBody(_ jsonBody: Data, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        let encrypted = AES256Util.encrypt(data: jsonBody)
        guard !encrypted.isEmpty else {
            failure(NSError(domain: "TagWorks.SecurityError", code: -2, userInfo: [NSLocalizedDescriptionKey : "AES Encryption Failed."]))
            return
        }
        
        // 취약점 발견으로 인한 암호화 적용
        // ##@ 를 붙이는 이유: 해당 패킷은 AES로 암호화 되어 있다는 표시
        let encryptedData: Data = ("##@" + encrypted).data(using: .utf8)!
        TagWorks.log("send Json AES Body: \(String(data: encryptedData, encoding: .utf8)!)")
        
        guard let baseURL = self.baseUrl else {
            failure(NSError(domain: "TagWorks.NetworkError", code: -999, userInfo: [NSLocalizedDescriptionKey: "Base URL is nil"]))
            return
        }
        
        let request = buildRequest(baseURL: baseURL, method: "POST", contentType: "application/json; charset=utf-8", body: encryptedData)
        send(request: request, success: success, failure: failure)
    }
}
