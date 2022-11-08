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
        view.backgroundColor = .blue
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
    
    override func viewWillLayoutSubviews() {
        self.changeFrmae()
    }
    
    func changeFrmae() {
        self.view.frame = CGRectMake(0, 0, 100, 400)
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .getRecentCardBackgroundImgSuccess(let background):
                    DispatchQueue.main.async(execute: {
                //        self.someImageView.image = background
                        print("CardBackgroundViewController import background image from view Model")
                    })
                case .getRecentCardBackgroundImgFail:
                    DispatchQueue.main.async(execute: {
                        //  self.someImageView.image = UIImage(named: "Rectangle")
                    })
                case .getRecentCardResultImgSuccess(_):
                    DispatchQueue.main.async(execute: {
                    })
                case .getRecentCardResultImgFail:
                    DispatchQueue.main.async(execute: {
                    })
                }
            })
            .store(in: &cancellables)
    }
    
    lazy var firstColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[0])"), for: .normal)
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if backgroundImageName[0] == "Rectangle_white" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(firstImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var secondColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[1])"), for: .normal)
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if backgroundImageName[1] == "Rectangle_white" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(secondImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var thirdColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[2])"), for: .normal)
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if backgroundImageName[2] == "Rectangle_white" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(thirdImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var fourthColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[3])"), for: .normal)
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if backgroundImageName[3] == "Rectangle_white" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(fourthImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func firstImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("firstImageViewColor clicked")
        guard let image = UIImage(named: "\(backgroundImageName[0])") else { return }
     //   self.someImageView.image = image
    }
    
    @objc func secondImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("secondImageViewColor clicked")
        guard let image = UIImage(named: "\(backgroundImageName[1])") else { return }
     //   self.someImageView.image = image
    }
    
    @objc func thirdImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("secondImageViewColor clicked")
        guard let image = UIImage(named: "\(backgroundImageName[2])") else { return }
     //   self.someImageView.image = image
    }
    
    @objc func fourthImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("fourthImageViewColor clicked")
        guard let image = UIImage(named: "\(backgroundImageName[3])") else { return }
     //   self.someImageView.image = image
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
    
    func selfConstraints() {
        self.view.snp.makeConstraints({ make in
            make.width.equalTo(100)
            make.height.equalTo(200)
        })
    }
    
    func firstColorButtonConstraints() {
        firstColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(self.view.snp.leading).offset(28)
            make.top.equalTo(self.view.snp.top).offset(20)
        })
    }
    
    func secondColorButtonConstraints() {
        secondColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(self.view.snp.leading).offset(28)
            make.top.equalTo(firstColorBackgroundButton.snp.bottom).offset(20)
        })
    }
    
    func thirdColorButtonConstraints() {
        thirdColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(self.view.snp.leading).offset(28)
            make.top.equalTo(secondColorBackgroundButton.snp.bottom).offset(20)
        })
    }
    
    func fourthColorButtonConstraints() {
        fourthColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(self.view.snp.leading).offset(28)
            make.top.equalTo(thirdColorBackgroundButton.snp.bottom).offset(20)
        })
    }
}
