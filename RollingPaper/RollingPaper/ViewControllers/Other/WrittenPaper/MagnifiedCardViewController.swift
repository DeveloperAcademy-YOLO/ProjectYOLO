//
//  MagnifiedCardViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/26.
//

import Foundation
import UIKit
import SnapKit

class MagnifiedCardViewController: UIViewController {
    var cardContentURLString: String?
    var magnifiedCardImage = UIImageView()
    var closeBtn: UIButton = UIButton()
    var parentNavigationBarHeight: CGFloat?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isOpaque = false
        view.backgroundColor = .clear
        self.closeBtn.addTarget(self, action: #selector(closeAction), for: UIControl.Event.touchUpInside)
        magnifiedCardImage.translatesAutoresizingMaskIntoConstraints = false
        magnifiedCardImage.isUserInteractionEnabled = true
        magnifiedCardImage.backgroundColor = .systemBackground
        magnifiedCardImage.layer.masksToBounds = true
        magnifiedCardImage.layer.cornerRadius = 50
        magnifiedCardImage.contentMode = .scaleAspectFill
        setCustomBlurEffect()
        view.addSubview(magnifiedCardImage)
        view.addSubview(closeBtn)
        setImageSize()
        setBtnSize()
    }
    
    @objc func closeAction() {
        dismiss(animated: true)
    }
    
    func setCustomBlurEffect() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, at: 0)
        
        blurView.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(parentNavigationBarHeight!)
            make.leading.equalTo(self.view).offset(0)
            make.bottom.equalTo(self.view).offset(0)
            make.trailing.equalTo(self.view).offset(0)
        }
    }
    
    func setBtnSize() {
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(0)
            make.leading.equalTo(self.view).offset(0)
            make.bottom.equalTo(self.view).offset(0)
            make.trailing.equalTo(self.view).offset(0)
        }
    }
    
    func setImageSize() {
        magnifiedCardImage.snp.makeConstraints { make in
            make.width.equalTo(self.view.bounds.width * 0.75)
            make.height.equalTo(self.view.bounds.width * 0.75 * 0.75)
            make.leading.equalTo(self.view.snp.leading).offset(self.view.bounds.width * 0.125)
            make.trailing.equalTo(self.view.snp.trailing).offset(-(self.view.bounds.width * 0.125))
            make.top.equalTo(self.view.snp.top).offset(120)
            make.bottom.equalTo(self.view.snp.bottom).offset(-90)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        }
    } //확대된 카드의 사이즈 결정
}
