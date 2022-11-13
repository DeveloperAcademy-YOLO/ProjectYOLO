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
    
    var deviceWidth = UIScreen.main.bounds.size.width
    var deviceHeight = UIScreen.main.bounds.size.height
    var cardIsDismissed: Bool = false
    
    private lazy var closeBtn: UIButton = UIButton()
    let presentingVC = MagnifiedCardViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(blurView)
        view.addSubview(closeBtn)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        animationIN()
        setCloseBtn()
        setBlurView()
        
        
    }
    
    func presentBlurredView() {
        if cardIsDismissed == false
        {
            print("cardIsDismissed : \(cardIsDismissed)")
            UIView.animate(withDuration: 0.4) {
                self.blurView.effect = UIBlurEffect(style: .systemThinMaterial)
            }
        }
        else{
            print("cardIsDismissed : \(cardIsDismissed)")
            UIView.animate(withDuration: 0.4) {
                self.blurView.effect = nil
            }
            dismiss(animated: true)
        }
    }
    
    func animationIN() {
        print("cardIsDismissed : \(cardIsDismissed)")
        if cardIsDismissed == false
        {
            UIView.animate(withDuration: 0.4) {
                self.blurView.effect = UIBlurEffect(style: .systemThinMaterial)
            }
        }
    }
    
    func animationOut() {
        print("cardIsDismissed : \(cardIsDismissed)")
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
