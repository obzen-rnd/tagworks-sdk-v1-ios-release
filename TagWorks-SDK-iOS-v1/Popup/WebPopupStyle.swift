//
//  WebPopupStyle.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 3/6/25.
//

import Foundation
import UIKit

class WebPopupStyle: NSObject {
    
    // 전체 설정
    let dupDisplayDelay: Int            // 동일 팝업 노출 방지를 위한 설정값 (seconds)
    let popupTitleUse: String           // 타이틀바 사용 여부
    let popupType: String!              // 팝업 타입
    let closeBtnGrpType: String!        // 닫기 버튼 타입 (1: Only 닫기, 2: 옵션 포함 닫기)
    let autoCloseSec: Int!              // 자동 닫기 시간(초)
    let closeBtnPosition: String        // 닫기 버튼 위치 (bottom, top, intop)
    
    // 바디
    let webViewWidth: CGFloat!
    let webViewHeight: CGFloat!
    let webViewRadius: CGFloat!
    let webViewBgColor: String!         // 웹뷰 배경 컬러
    let webViewBgAlpha: CGFloat!        // 팝업 외 배경 투명도
    let bgCloseOption: String!          // 팝업 외 배경 터치 시 창 닫기 기능 사용 설정
    
    // 타이틀바
    let popupTitleHeight: CGFloat!
    let popupTitle: String!
    let popupTitleTextAlign: String!
    let popupTitleFontSize: Int!
    let popupTitleFontColor: String!
    let popupTitleBgColor: String!
    
    // 버튼
    let closeBtnGrpHeight: CGFloat!
    let closeBtnGrpFontSize: Int!
    let closeOptBtnType: String!
    let closeOptBtnFontColor: String!
    let closeOptBtnBgColor: String!
    let closeBtnFontColor: String!
    let closeBtnBgColor: String!
    
    // 필요한 변수 설정
    let popupSideMargin: CGFloat = 30
    let topCloseBtnHeight: CGFloat = 20
    let screenWidth: CGFloat = UIScreen.main.bounds.width
    let screenHeight: CGFloat = UIScreen.main.bounds.height
    
    // webView의 ratio 계산
    var webViewAspectRatio: CGFloat {
        get {
            if let webViewWidth = webViewWidth, let webViewHeight = webViewHeight {
                return (webViewHeight / webViewWidth)
            }
            return 1
        }
    }
    
    // 타이틀뷰의 ratio 계산
//    var popupTitleAspectRatio: CGFloat {
//        get {
//            if let webViewWidth = webViewWidth, let popupTitleHeight = popupTitleHeight {
//                return (popupTitleHeight / webViewWidth)
//            }
//            return 1
//        }
//    }
//    
//    // 닫기 버튼 그룹의 ratio 계산
//    var closeBtnGrpAspectRatio: CGFloat {
//        get {
//            if let webViewWidth = webViewWidth, let closeBtnGrpHeight = closeBtnGrpHeight {
//                return (closeBtnGrpHeight / webViewWidth)
//            }
//            return 1
//        }
//    }
    
    func getCalcNewWebViewHeight(currentWidth: CGFloat) -> CGFloat {
        return currentWidth * webViewAspectRatio
    }
    
    func getCalcNewTitleViewHeight(currentWidth: CGFloat) -> CGFloat {
        let newWidthRatio = currentWidth / webViewWidth
        return popupTitleHeight * newWidthRatio
    }
    
    func getCalcNewCloseBtnGrpHeight(currentWidth: CGFloat) -> CGFloat {
        let newWidthRatio = currentWidth / webViewWidth
        return closeBtnGrpHeight * newWidthRatio
    }
    
    func getCalcNewTopCloseBtnHeight(currentWidth: CGFloat) -> CGFloat {
        let newWidthRatio = currentWidth / webViewWidth
        return topCloseBtnHeight * newWidthRatio
    }
    
    func ratioTitleFontSize(currentWidth: CGFloat) -> CGFloat {
        if let popupTitleFontSize = popupTitleFontSize, let webViewWidth = webViewWidth {
            let newWidthRatio = currentWidth / webViewWidth
            let newFontSize = CGFloat(popupTitleFontSize) * newWidthRatio
            return newFontSize
        }
        return CGFloat(popupTitleFontSize!)
    }
    
    func ratioCloseBtnGrpFontSize(currentWidth: CGFloat) -> CGFloat {
        if let closeBtnGrpFontSize = closeBtnGrpFontSize, let webViewWidth = webViewWidth {
            let newWidthRatio = currentWidth / (webViewWidth / 2)
            let newFontSize = CGFloat(closeBtnGrpFontSize) * newWidthRatio
            return newFontSize
        }
        return CGFloat(closeBtnGrpFontSize!)
    }
    
    func ratioWebviewCornerRadius(currentWidth: CGFloat) -> CGFloat {
        if let webViewRadius = webViewRadius, let webViewWidth = webViewWidth {
            return webViewRadius * (CGFloat(currentWidth) / CGFloat(webViewWidth))
        }
        return webViewRadius!
    }
    
    override public init() {
        dupDisplayDelay = 10
        popupTitleUse = "0"
        popupType = "S"
        closeBtnGrpType = "1"
        autoCloseSec = 0
        closeBtnPosition = "bottom"
        
        webViewWidth = 320
        webViewHeight = 350
        webViewRadius = 15
        webViewBgColor = "#ffffff"
        webViewBgAlpha = 0.5
        bgCloseOption = "1"
        
        popupTitleHeight = 30
        popupTitle = "알림"
        popupTitleTextAlign = "center"
        popupTitleFontSize = 13
        popupTitleFontColor = "#cdcdcd"
        popupTitleBgColor = "#ffffff"
        
        closeBtnGrpHeight = 30
        closeBtnGrpFontSize = 10
        closeOptBtnType = "1"
        closeOptBtnFontColor = "#ffffff"
        closeOptBtnBgColor = "#ff5018"
        closeBtnFontColor = "#414141"
        closeBtnBgColor = "#ffffff"
        
        super.init()
    }
    
    public init(styleJson: [String: Any]) {
        dupDisplayDelay = styleJson["dupDisplayDelay"] as? Int ?? 10
        popupTitleUse = styleJson["popupTitleUse"] as? String ?? "0"
        popupType = styleJson["popupType"] as? String ?? "S"
        closeBtnGrpType = styleJson["closeBtnGrpType"] as? String ?? "1"
        autoCloseSec = styleJson["autoCloseSec"] as? Int ?? 0
        closeBtnPosition = styleJson["closeBtnPosition"] as? String ?? "bottom"
//        closeBtnPosition = "bottom"
        
        webViewWidth = styleJson["webViewWidth"] as? CGFloat ?? 320
        webViewHeight = styleJson["webViewHeight"] as? CGFloat ?? 350
        webViewRadius = styleJson["webViewRadius"] as? CGFloat ?? 15
        webViewBgColor = styleJson["webViewBgColor"] as? String ?? "#ffffff"
        webViewBgAlpha = styleJson["webViewBgAlpha"] as? CGFloat ?? 0.5
        bgCloseOption = styleJson["bgCloseOption"] as? String ?? "1"
        
        popupTitleHeight = styleJson["popupTitleHeight"] as? CGFloat ?? 30
        popupTitle = styleJson["popupTitle"] as? String ?? "알림"
        popupTitleTextAlign = styleJson["popupTitleTextAlign"] as? String ?? "center"
        popupTitleFontSize = styleJson["popupTitleFontSize"] as? Int ?? 13
        popupTitleFontColor = styleJson["popupTitleFontColor"] as? String ?? "#cdcdcd"
        popupTitleBgColor = styleJson["popupTitleBgColor"] as? String ?? "#ffffff"
        
        closeBtnGrpHeight = styleJson["closeBtnGrpHeight"] as? CGFloat ?? 30
        closeBtnGrpFontSize = styleJson["closeBtnGrpFontSize"] as? Int ?? 10
        closeOptBtnType = styleJson["closeOptBtnType"] as? String ?? "1"
        closeOptBtnFontColor = styleJson["closeOptBtnFontColor"] as? String ?? "#ffffff"
        closeOptBtnBgColor = styleJson["closeOptBtnBgColor"] as? String ?? "#ff5018"
        closeBtnFontColor = styleJson["closeBtnFontColor"] as? String ?? "#414141"
        closeBtnBgColor = styleJson["closeBtnBgColor"] as? String ?? "#ffffff"
        
        super.init()
    }
}
