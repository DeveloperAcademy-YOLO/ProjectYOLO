//
//  CardBackgroundViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/05.
//

import UIKit
import SnapKit
import AVFoundation
import Photos
import Combine

final class BackgroundButtonViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let backgroundImageName: [String]
    private let viewModel: CardViewModel
    private let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    lazy var firstColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[0])"), for: .normal)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        let checkBorder = backgroundImageName[0].suffix(5)
        if checkBorder == "white" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(firstImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var secondColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[1])"), for: .normal)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        let checkBorder = backgroundImageName[1].suffix(5)
        if checkBorder == "white" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(secondImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var thirdColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[2])"), for: .normal)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        let checkBorder = backgroundImageName[2].suffix(5)
        if checkBorder == "white" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(thirdImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var fourthColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[3])"), for: .normal)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        let checkBorder = backgroundImageName[3].suffix(5)
        if checkBorder == "white" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(fourthImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    init(viewModel: CardViewModel, backgroundImageName: [String]) {
        self.viewModel = viewModel
        self.backgroundImageName = backgroundImageName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        selfConstraints()
        
        view.addSubview(firstColorBackgroundButton)
        firstColorButtonConstraints()
        
        view.addSubview(secondColorBackgroundButton)
        secondColorButtonConstraints()
        
        view.addSubview(thirdColorBackgroundButton)
        thirdColorButtonConstraints()
        
        view.addSubview(fourthColorBackgroundButton)
        fourthColorButtonConstraints()
        
        input.send(.viewDidLoad)
        bind()
    }
    
    private func bind() {
        _ = viewModel.transform(input: input.eraseToAnyPublisher())
    }
    
    override func viewWillLayoutSubviews() {
        self.changeFrmae()
    }
    
    func changeFrmae() {
        self.view.frame = CGRect(x: 0, y: 0, width: 128, height: 400)
    }
    @objc func firstImageViewColor(_ gesture: UITapGestureRecognizer) {
        self.input.send(.setCardBackgroundImg(background: backgroundImageName[0]))
    }
    
    @objc func secondImageViewColor(_ gesture: UITapGestureRecognizer) {
        self.input.send(.setCardBackgroundImg(background: backgroundImageName[1]))
    }
    
    @objc func thirdImageViewColor(_ gesture: UITapGestureRecognizer) {
        self.input.send(.setCardBackgroundImg(background: backgroundImageName[2]))
    }
    
    @objc func fourthImageViewColor(_ gesture: UITapGestureRecognizer) {
        self.input.send(.setCardBackgroundImg(background: backgroundImageName[3]))
    }
}

extension UIButton {
    func setImage(systemName: String) {
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        imageView?.contentMode = .scaleAspectFit
        imageEdgeInsets = .zero
        setImage(UIImage(systemName: systemName), for: .normal)
    }
}

extension BackgroundButtonViewController {
    
    private func selfConstraints() {
        self.view.snp.makeConstraints({ make in
            make.width.equalTo(100)
            make.height.equalTo(200)
        })
    }
    
    private func firstColorButtonConstraints() {
        firstColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(100)
            make.height.equalTo(80)
            make.leading.equalTo(self.view.snp.leading).offset(28)
            make.top.equalTo(self.view.snp.top).offset(17)
        })
    }
    
    private func secondColorButtonConstraints() {
        secondColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(100)
            make.height.equalTo(80)
            make.leading.equalTo(self.view.snp.leading).offset(28)
            make.top.equalTo(firstColorBackgroundButton.snp.bottom).offset(15)
        })
    }
    
    private func thirdColorButtonConstraints() {
        thirdColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(100)
            make.height.equalTo(80)
            make.leading.equalTo(self.view.snp.leading).offset(28)
            make.top.equalTo(secondColorBackgroundButton.snp.bottom).offset(15)
        })
    }
    
    private func fourthColorButtonConstraints() {
        fourthColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(100)
            make.height.equalTo(80)
            make.leading.equalTo(self.view.snp.leading).offset(28)
            make.top.equalTo(thirdColorBackgroundButton.snp.bottom).offset(15)
        })
    }
}
