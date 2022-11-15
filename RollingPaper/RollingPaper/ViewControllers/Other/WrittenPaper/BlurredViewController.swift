//
//  BlurredViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/11/13.
//

import Foundation
import SnapKit
import UIKit

class BlurredViewController: UIViewController {
    lazy var blurView = UIVisualEffectView()
    
    private let deviceWidth = UIScreen.main.bounds.size.width
    private let deviceHeight = UIScreen.main.bounds.size.height
    private let cardIsDismissed: Bool = false
    
    private lazy var closeBtn: UIButton = UIButton()
    private let presentingVC = MagnifiedCardViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(blurView)
        view.addSubview(closeBtn)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        animationIn()
        setCloseBtn()
        setBlurView()
        
        
    }
    
    private func presentBlurredView() {
        cardIsDismissed == false
        ? UIView.animate(withDuration: 0.4) {
            self.blurView.effect = UIBlurEffect(style: .systemThinMaterial)
        }
        
        : UIView.animate(withDuration: 0.4) {
            self.blurView.effect = nil
        }
        dismiss(animated: true)
        
    }
    
    func animationIn() {
        if cardIsDismissed == false
        {
            UIView.animate(withDuration: 0.4) {
                self.blurView.effect = UIBlurEffect(style: .systemThinMaterial)
            }
        }
    }
    
    func animationOut() {
        if cardIsDismissed == true
        {
            UIView.animate(withDuration: 0.4) {
                self.blurView.effect = nil
                self.dismiss(animated: true)
            }
            
        }
    }
    
    @objc func closeAction() {
        UIView.animate(withDuration: 0.4) {
            self.blurView.effect = nil
            self.dismiss(animated: true)
        }
        
    }
}

extension BlurredViewController {
    func setCloseBtn() {
        closeBtn.addTarget(self, action: #selector(closeAction), for: UIControl.Event.touchUpInside)
        closeBtn.snp.makeConstraints { make in
            make.width.equalTo(deviceWidth)
            make.height.equalTo(deviceHeight)
        }
    }
    func setBlurView() {
        blurView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.equalTo(0)
            make.width.equalTo(deviceWidth)
            make.height.equalTo(deviceHeight)
        }
    }
}