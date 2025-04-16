//
//  RestApiManager.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 2/25/25.
//

import Foundation

class RestApiManager: NSObject {
    
    public func onCMSBridgePopup(onCmsUrl: String, cust_id: String, rcmd_area_cd: String, vstor_id: String, cntn_id: String, completionHandler: @escaping (Bool, Any) -> Void)  {
        // get url
        let parameters: [String: Any] = [
            "cust_id": cust_id,
            "rcmd_area_cd": rcmd_area_cd,
            "vstor_id": vstor_id,
            "cntn_id": cntn_id
        ]
        
        request(onCmsUrl, "GET", parameters) { success, data in
            completionHandler(success, data)
        }
        
        
        //        requestForResultString("http://192.168.20.53:89/oncms?cust_id=testuser&rcmd_area_cd=M_POP_MAIN_002", "GET") { success, data in
        //        requestForResultString("http://192.168.20.53:89/oncms?cust_id=testuser&rcmd_area_cd=NEW_AREA_1", "GET") { success, data in
        //        request("https://dxlab.obzen.com/oncms2?rcmd_area_cd=POPUP_TEST_AREA&cust_id=C0000004933", "GET") { success, data in
    }
    
    public func onCMSBridgePopupBanner(onCmsUrl: String, cust_id: String, rcmd_area_cd: String, vstor_id: String, cntn_id: String, completionHandler: @escaping (Bool, Any) -> Void)  {
        // get url
        let parameters: [String: Any] = [
            "cust_id": cust_id,
            "rcmd_area_cd": rcmd_area_cd,
            "vstor_id": vstor_id,
            "cntn_id": cntn_id
        ]
        
        requestForResultString(onCmsUrl, "GET", parameters) { success, data in
            completionHandler(success, data)
        }
    }
    
    /* 메소드별 동작 분리 */
    func request(_ url: String, _ method: String, _ param: [String: Any]? = nil, completionHandler: @escaping (Bool, Any) -> Void) {
        if method == "GET" {
            var getUrl = url
            if let param = param {
                getUrl = url + "?" + param.map { key, value in
                    return "\(key)=\(value)"
                }.joined(separator: "&")
            }
            
            requestGet(url: getUrl) { (success, data) in
                completionHandler(success, data)
            }
        }
        else {
            requestPost(url: url, method: method, param: param!) { (success, data) in
                completionHandler(success, data)
            }
        }
    }
    
    /* 메소드별 동작 분리 */
    func requestForResultString(_ url: String, _ method: String, _ param: [String: Any]? = nil, completionHandler: @escaping (Bool, Any) -> Void) {
        if method == "GET" {
            var getUrl = url
            if let param = param {
                getUrl = url + "?" + param.map { key, value in
                    return "\(key)=\(value)"
                }.joined(separator: "&")
            }
            
            requestGetForResultString(url: getUrl) { (success, data) in
                completionHandler(success, data)
            }
        }
        else {
            requestPostForResultString(url: url, method: method, param: param!) { (success, data) in
                completionHandler(success, data)
            }
        }
    }
    
    ///
    ///
    ///
    func requestGet(url: String, completionHandler: @escaping (Bool, Any) -> Void) {
        guard let url = URL(string: url) else {
            print("Error: cannot create URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error: error calling GET - \(error!)")
                completionHandler(false, error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode else {
                print("Error: HTTP request failed")
                return
            }
//            print(String(decoding: data, as: UTF8.self))
            
//            guard let output = try? JSONDecoder().decode(Response.self, from: data) else {
//                print("Error: JSON Data Parsing failed")
//                return
//            }
            do {
                if let output = try JSONSerialization.jsonObject(with: data, options:[]) as? [String: Any] {
                    completionHandler(true, output)
                    print("complete : \(output)")
                }
            } catch {
                completionHandler(false, error)
                print("디코딩 오류: \(error)")
                return
            }
            
        }.resume()
    }
    
    func requestGetForResultString(url: String, completionHandler: @escaping (Bool, Any) -> Void) {
        guard let url = URL(string: url) else {
            print("Error: cannot create URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error: error calling GET - \(error!)")
                completionHandler(false, error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                //                completionHandler(false, "")
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode else {
                print("Error: HTTP request failed")
                //                completionHandler(false, "")
                return
            }
            if data.count != 0 {
                let htmlString = String(decoding: data, as: UTF8.self)
                print(htmlString)
                completionHandler(true, htmlString)
            }
            
            completionHandler(false, error as Any)
            
//            guard let output = try? JSONDecoder().decode(Response.self, from: data) else {
//                print("Error: JSON Data Parsing failed")
//                return
//            }

//            completionHandler(true, output.result)
            
        }.resume()
    }
    
    func requestPost(url: String, method: String, param: [String: Any], completionHandler: @escaping (Bool, Any) -> Void) {
        let sendData = try! JSONSerialization.data(withJSONObject: param, options: [])
        
        guard let url = URL(string: url) else {
            print("Error: cannot create URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = sendData
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("Error: error calling GET")
                print(error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode else {
                print("Error: HTTP request failed")
                return
            }
//            guard let output = try? JSONDecoder().decode(Response.self, from: data) else {
//                print("Error: JSON Data Parsing failed")
//                return
//            }
            do {
                let output = try JSONSerialization.jsonObject(with: data, options:[])
                completionHandler(true, output)
                print("complete : \(output)")
            } catch {
                completionHandler(false, error)
                print("디코딩 오류: \(error)")
                return
            }
        }.resume()
    }
    
    func requestPostForResultString(url: String, method: String, param: [String: Any], completionHandler: @escaping (Bool, Any) -> Void) {
        let sendData = try! JSONSerialization.data(withJSONObject: param, options: [])
        
        guard let url = URL(string: url) else {
            print("Error: cannot create URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = sendData
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("Error: error calling GET")
                print(error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode else {
                print("Error: HTTP request failed")
                return
            }
//            guard let output = try? JSONDecoder().decode(Response.self, from: data) else {
//                print("Error: JSON Data Parsing failed")
//                return
//            }
            
            if data.count != 0 {
                let resultString = String(decoding: data, as: UTF8.self)
                print(resultString)
                completionHandler(true, resultString)
            }
            
            completionHandler(false, error as Any)
            
        }.resume()
    }
}
