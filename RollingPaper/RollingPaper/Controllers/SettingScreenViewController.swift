//
//  SettingScreenViewController.swift
//  RollingPaper
//
//  Created by 임 용관 on 2022/10/12.
//

import Foundation
import UIKit
import SnapKit

class SettingScreenViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }
    
    private let editButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.setTitle("편집", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    private let profileImage: UIImageView = {
       let profileImage = UIImageView()
        profileImage.contentMode = UIView.ContentMode.scaleAspectFill
        profileImage.image = UIImage(named: "Halloween_Pumpkin")
        
        let blurEffect = UIBlurEffect(style: .regular)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = profileImage.bounds
        visualEffectView.alpha = 0.5
        profileImage.addSubview(visualEffectView)
        
        
        return profileImage
    }()
    
    private let blurprofileImage: UIImageView = {
        let profileImage = UIImageView()
        profileImage.image = UIImage(systemName: "photo.on.rectangle.angled")
        return profileImage
    }()
    
    private let profileText: UITextField = {
        let textField = UITextField()
        textField.layer.masksToBounds = false
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1.0
        
        let customFont:UIFont = UIFont.init(name: (textField.font?.fontName)!, size: 28.0)!
        let font = customFont
        textField.font = customFont
        
        textField.layer.borderColor = UIColor.systemBackground.cgColor
        textField.attributedPlaceholder = NSAttributedString(string: "Yosep", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    private let divideView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor.gray
        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor.systemPink.cgColor
        return view
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.setTitle("로그아웃", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        return button
    }()
    
    private let resignButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.setTitle("회원탈퇴", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        return button
    }()
        
    private func createBlur(_ profile: UIImageView) {
        let blurEffect = UIBlurEffect(style: .regular)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = profile.bounds
        visualEffectView.alpha = 0.5
        profile.addSubview(visualEffectView)
//        view.addSubview(visualEffectView)
    }
    
    private func setupLayout() {
        
        view.addSubview(profileImage)

        let blurEffect = UIBlurEffect(style: .regular)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame.self = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
//        visualEffectView.frame = profileImage.bounds
        visualEffectView.alpha = 0.5
        profileImage.addSubview(visualEffectView)
        profileImage.addSubview(blurprofileImage)
        
        view.addSubview(profileText)
        view.addSubview(divideView)
        view.addSubview(logoutButton)
        view.addSubview(resignButton)
        view.addSubview(editButton)
        view.backgroundColor = .white
        
        editButton.snp.makeConstraints { make in

            make.top.equalTo(37)
            make.trailing.equalTo(-38)
            
            make.height.equalTo(24)
            make.width.equalTo(37)
        }
        
        profileImage.snp.makeConstraints ({ make in
            make.top.equalTo(200)
            make.centerX.equalToSuperview()
            make.height.equalTo(180)
            make.width.equalTo(180)
        })
        
        blurprofileImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        profileText.snp.makeConstraints { make in
            make.top.equalTo(profileImage.snp.bottom).offset(47)
            make.centerX.equalToSuperview()
        }
        
        divideView.snp.makeConstraints ({ make in
            make.top.equalTo(profileText.snp.bottom).offset(26)
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
            make.width.equalTo(260)
        })
        
        logoutButton.snp.makeConstraints({ make in
            make.top.equalTo(divideView.snp.bottom).offset(27)
            make.centerX.equalToSuperview()
        })
        
        resignButton.snp.makeConstraints({ make in
            make.top.equalTo(logoutButton.snp.bottom).offset(24)
            make.centerX.equalTo(view)
        })
    }
}
