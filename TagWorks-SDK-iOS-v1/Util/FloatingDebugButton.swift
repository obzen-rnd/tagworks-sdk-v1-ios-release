//
//  FloatingDebugButton.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 11/4/25.
//

import Foundation
import UIKit
import ObjectiveC

private var ActionKey: UInt8 = 0

public class FloatingDebugButton {
    
    public static let sharedInstance = FloatingDebugButton()
    private var button: UIButton?
    private var valueProvider: (() -> String)?
    
    public func show(provider: @escaping () -> String) {
        guard button == nil else { return }
        valueProvider = provider
        
        let button = UIButton(type: .custom)
        button.setTitle("🏷️", for: .normal)
        button.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        button.layer.cornerRadius = 25
        button.frame = CGRect(x: UIScreen.main.bounds.width - 70, y: UIScreen.main.bounds.height / 2, width: 50, height: 50)
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        
        if let window = UIApplication.shared.windows.first {
            window.addSubview(button)
        }
        
        self.button = button
    }
    
    @objc private func onTap() {
        guard let text = valueProvider?() else { return }
        let alert = UIAlertController(title: "현재 값", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
    
    public func hide() {
        button?.removeFromSuperview()
        button = nil
    }
}

public class FloatingDebugMenu {
    
    public static let sharedInstance = FloatingDebugMenu()
    private var mainButton: UIButton?
    private var menuButtons: [UIButton] = []
    private var isExpanded = false
    private var actions: [(String, () -> Void)] = []
    private var panGesture: UIPanGestureRecognizer?

    public func show(actions: [(String, () -> Void)]) {
        guard mainButton == nil else { return }
        self.actions = actions

        let button = UIButton(type: .custom)
//        button.setTitle("⚙️", for: .normal)
        button.setTitle("🏷️", for: .normal)
        button.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        button.frame = CGRect(x: UIScreen.main.bounds.width - 70, y: UIScreen.main.bounds.height / 2, width: 50, height: 50)
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag))
        button.addGestureRecognizer(panGesture!)

        UIApplication.shared.windows.first?.addSubview(button)
        mainButton = button
    }
    
    @objc private func handleDrag(_ gesture: UIPanGestureRecognizer) {
        guard let button = mainButton, let window = UIApplication.shared.windows.first else { return }
        collapseMenu()
        let translation = gesture.translation(in: window)
        switch gesture.state {
        case .changed:
            button.center = CGPoint(x: button.center.x + translation.x, y: button.center.y + translation.y)
            gesture.setTranslation(.zero, in: window)
        default: break
        }
    }

    @objc private func toggleMenu() {
        isExpanded ? collapseMenu() : expandMenu()
    }

    private func expandMenu() {
        guard let mainButton = mainButton else { return }
        collapseMenu()

        var offsetY: CGFloat = 60
        var offsetX: CGFloat = UIScreen.main.bounds.width - mainButton.frame.origin.x > 220 ? mainButton.frame.origin.x : UIScreen.main.bounds.width - 220
        if offsetX <= 0 { offsetX = 20 }
        for (title, action) in actions {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
            btn.setTitleColor(.white, for: .normal)
            btn.layer.cornerRadius = 8
            btn.frame = CGRect(x: offsetX, y: mainButton.frame.origin.y + 100 + offsetY, width: 200, height: 35)
            btn.alpha = 0
            // ✅ iOS 12 호환 클로저 방식
            btn.addAction(for: .touchUpInside) {
                action()
                self.collapseMenu()
            }

            UIApplication.shared.windows.first?.addSubview(btn)
            UIView.animate(withDuration: 0.2) { btn.alpha = 1 }
            menuButtons.append(btn)
            offsetY -= 45
        }
        isExpanded = true
    }
    
    private func collapseMenu() {
        menuButtons.forEach { $0.removeFromSuperview() }
        menuButtons.removeAll()
        isExpanded = false
    }

    public func hide() {
        collapseMenu()
        mainButton?.removeFromSuperview()
        mainButton = nil
    }
}

extension UIControl {
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping () -> Void) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, &ActionKey, sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

private class ClosureSleeve {
    let closure: () -> Void
    init(_ closure: @escaping () -> Void) { self.closure = closure }
    @objc func invoke() { closure() }
}
