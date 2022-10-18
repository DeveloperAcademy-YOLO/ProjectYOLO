//
//  SettingScreenViewController.swift
//  RollingPaper
//
//  Created by 임 용관 on 2022/10/12.
//

import Foundation
import UIKit
import SnapKit
import Combine
import CombineCocoa

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
        let profileImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 180, height: 180))
        profileImage.layer.cornerRadius = profileImage.frame.size.width * 0.5
        profileImage.image = UIImage(named: "Halloween_Pumpkin")
        profileImage.contentMode = UIView.ContentMode.scaleAspectFit
        profileImage.backgroundColor = .systemGray6
        //        profileImage.layer.borderColor = UIColor.red.cgColor
        
        //        profileImage.layer.borderWidth = 3.0
        //        profileImage.clipsToBounds = true
        //        profileImage.layer.masksToBounds = true
        return profileImage
    }()
    
    private let editPhotoButton: UIButton = {
        let profileImage = UIButton()
        profileImage.setBackgroundImage(UIImage(systemName: "photo.on.rectangle.angled"), for: .normal)
        profileImage.isHidden = true
        return profileImage
    }()
    
    private let profileText: SignUpTextField = {
        let textField = SignUpTextField()
        textField.isHidden = true
        return textField
    }()
    
    private let profileLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.text = "Yosep"
        textLabel.font = .preferredFont(forTextStyle: .title1)
        textLabel.textAlignment = .center
        
        return textLabel
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
    
    lazy var pencilToggleButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "pencil.and.outline")
        button.tintColor = .lightGray
        return button
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    
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
    
    @objc func didEditButton() {
        if let currentTitle = navigationItem.rightBarButtonItem?.title {
            if currentTitle == "편집" {
                navigationItem.rightBarButtonItem?.title = "완료"
                divideView.isHidden = true
                logoutButton.isHidden = true
                resignButton.isHidden = true
                profileText.isHidden = false
                visualEffectView.isHidden = false
                editPhotoButton.isHidden = false
                profileLabel.isHidden = true
            } else if currentTitle == "완료" {
                navigationItem.rightBarButtonItem?.title = "편집"
                divideView.isHidden = false
                logoutButton.isHidden = false
                resignButton.isHidden = false
                profileText.isHidden = true
                visualEffectView.isHidden = true
                editPhotoButton.isHidden = true
                profileLabel.isHidden = false
            }
        }
        
    }
    
    private let visualEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame.self = CGRect(origin: .zero, size: CGSize(width: 180, height: 180))
        visualEffectView.layer.cornerRadius = visualEffectView.frame.size.width / 2
        visualEffectView.clipsToBounds = true
        visualEffectView.alpha = 0.5
        visualEffectView.isHidden = true
        return visualEffectView
    }()
    
    private func setupLayout() {
        
        view.addSubview(profileImage)

        profileImage.addSubview(visualEffectView)
        profileImage.addSubview(editPhotoButton)
        
        view.addSubview(profileText)
        view.addSubview(profileLabel)
        view.addSubview(divideView)
        view.addSubview(logoutButton)
        view.addSubview(resignButton)
        view.addSubview(editButton)
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "편집", style: .done, target: self, action: #selector(didEditButton))
        
//        editButton.snp.makeConstraints{make in
//            make.top.equalTo(37)
//            make.trailing.equalTo(-38)
//            make.height.equalTo(24)
//            make.width.equalTo(37)
//        }
        
        
        profileImage.snp.makeConstraints ({ make in
            make.top.equalTo(200)
            make.centerX.equalToSuperview()
            make.height.equalTo(180)
            make.width.equalTo(180)
        })
        
        editPhotoButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(39)
            make.width.equalTo(48)
        }
        
        profileLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImage.snp.bottom).offset(47)
            make.width.equalTo(318)
            make.centerX.equalToSuperview()
        }
        
        profileText.snp.makeConstraints { make in
            make.top.equalTo(profileImage.snp.bottom).offset(47)
            make.width.equalTo(318)
            make.centerX.equalToSuperview()
        }
        profileText.setTextFieldType(type: .name)
        
        divideView.snp.makeConstraints ({ make in
            make.top.equalTo(profileLabel.snp.bottom).offset(26)
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
    
//    private func bind() {
//        viewModel
//            .textSubject
//            .sink()
//            .store()
//
//    }
}
