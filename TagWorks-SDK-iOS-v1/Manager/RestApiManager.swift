//
//  RestApiManager.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 2/25/25.
//

import Foundation

class RestApiManager: NSObject {
    // MARK: Deeplink Proxy 서버 URL을 SDK 초기화 시에 입력 받도록 추가할 것!!!
//    public var deferredDeeplinkURL = "https://dxlab.obzen.com/ozsmlinkg"
    
    // MARK: - InApp Message API
    ///
    /// onCMS를 이용한 InAppMessage API 호출
    ///
    public func onCMSBridgePopup(onCmsUrl: String,
                                 cust_id: String,
                                 rcmd_area_cd: String,
                                 vstor_id: String,
                                 cntn_id: String,
                                 completionHandler: @escaping (Bool, Any) -> Void) {
        let parameters: [String: Any] = [
            "cust_id": cust_id,
            "rcmd_area_cd": rcmd_area_cd,
            "vstor_id": vstor_id,
            "cntn_id": cntn_id
        ]
        
        request(url: onCmsUrl,
                method: "GET",
                parameters: parameters,
                responseType: .json,
                completionHandler: completionHandler)
    }
    
    /// onCMS를 이용한 InAppBanner API 호출
    public func onCMSBridgePopupBanner(onCmsUrl: String,
                                       cust_id: String,
                                       rcmd_area_cd: String,
                                       vstor_id: String,
                                       cntn_id: String,
                                       completionHandler: @escaping (Bool, Any) -> Void) {
        let parameters: [String: Any] = [
            "cust_id": cust_id,
            "rcmd_area_cd": rcmd_area_cd,
            "vstor_id": vstor_id,
            "cntn_id": cntn_id
        ]
        
        request(url: onCmsUrl,
                method: "GET",
                parameters: parameters,
                responseType: .string,
                completionHandler: completionHandler)
    }
    
    // MARK: - Deferred Deeplink API
    ///
    /// 딥링크 Bridge를 이용한 디퍼드 딥링크 API 호출
    ///
    public func requestDeferredDeeplinkInfo(fp_basic: String,
                                           fp_canvas: String,
                                           fp_webgl: String,
                                           fp_audio: String,
                                           cntn_id: String,
                                           completionHandler: @escaping (Bool, Any) -> Void) {
        
        guard let deferredDeeplinkURL = TagWorks.sharedInstance.deferredDeeplinkURL else {
            completionHandler(false, "")
            return
        }
        
        let fpDetails: [String: String] = [
            "canvasHash": fp_canvas,
            "webglHash": fp_webgl,
            "audioHash": fp_audio
        ]
        
        let parameters: [String: Any] = [
            "oz_method": "get_install_info",
            "oz_cntn_id": cntn_id,
            "oz_fingerprint_basic": fp_basic,
            "oz_fingerprint_detail": fpDetails,
            "oz_ssaid": ""
        ]
        
        request(url: deferredDeeplinkURL.absoluteString,
                method: "POST",
                parameters: parameters,
                responseType: .json,
                completionHandler: completionHandler)
    }
}

// MARK: - Networking Layer
// 통신 호출 방식과 리턴 방식에 따른 통신 유틸리티 helper
extension RestApiManager {
    
    enum ResponseType {
        case json
        case string
    }
    
    func request(url: String,
                 method: String,
                 parameters: [String: Any]? = nil,
                 responseType: ResponseType,
                 completionHandler: @escaping (Bool, Any) -> Void) {
        
        var finalURL = url
        var request: URLRequest
        
        // GET 인 경우, 파라미터 처리
        if method == "GET", let params = parameters {
            let query = params.map { key, value in
                let keyEscaped = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let valueEscaped = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
                return "\(keyEscaped)=\(valueEscaped)"
            }.joined(separator: "&")
            finalURL += "?\(query)"
        }
        
        guard let requestURL = URL(string: finalURL) else {
            completionHandler(false, "Invalid URL")
            return
        }
        
        request = URLRequest(url: requestURL)
        request.httpMethod = method
        
        // POST 인 경우, 파라미터 및 설정
        if method != "GET", let params = parameters {
            guard let bodyData = try? JSONSerialization.data(withJSONObject: params, options: []) else {
                completionHandler(false, "Invalid parameters")
                return
            }
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Error case
            if let error = error {
                completionHandler(false, error.localizedDescription)
                return
            }
            
            // No data
            guard let data = data, !data.isEmpty else {
                completionHandler(false, "No data received")
                return
            }
            
            // Invalid status code
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                completionHandler(false, "Invalid HTTP response")
                return
            }
            
            switch responseType {
            case .json:
                do {
                    let result = try JSONSerialization.jsonObject(with: data, options: [])
                    completionHandler(true, result)
                } catch {
                    let dataString = "JSON Parsing failed: " + (String(data: data, encoding: .utf8) ?? "")
                    completionHandler(false, dataString)
                }
                
            case .string:
                let resultString = String(data: data, encoding: .utf8) ?? ""
                completionHandler(true, resultString)
            }
            
        }.resume()
    }
}
