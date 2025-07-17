//
//  BackgroundTaskManager.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 6/10/25.
//

import Foundation
import UIKit

class BackgroundTaskManager {
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    // 앱이 백그라운드 상태에서 백그라운드 Task를 만들어서 약 30초 동안 작업 시작
    func performBackgroundFetch() {
        // 백그라운드 작업 요청
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "FetchConfig") {
            // 시간이 다 되었을 때 호출되는 expirationHandler
            print("⏱️ Background time expired. Clean up.")
            self.endBackgroundTask()
        }

        print("🚀 Background task started.")

        // 서버 통신 (예: Remote Config 받아오기)
        fetchRemoteConfig { success in
            if success {
                print("✅ Config fetched successfully.")
            } else {
                print("❌ Failed to fetch config.")
            }

            self.endBackgroundTask()
        }
    }
    
    // 백그라운드 Task 시간이 종료되거나 작업이 종료되면 백그라운드 Task 작업 종료
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            print("🔚 Background task ended.")
            backgroundTaskID = .invalid
        }
    }

    // 백그라운드 상태에서 해야 할 작업들을 기술 정의
    private func fetchRemoteConfig(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://example.com/api/config")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }

            // 파싱 또는 저장 작업
            print("📦 Received data: \(data)")
            completion(true)
        }
        task.resume()
    }

    
}
