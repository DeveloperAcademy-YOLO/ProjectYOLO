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

final class CardBackgroundViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var backgroundImageName: [String] = ["Rectangle_black", "Rectangle", "Rectangle_red", "Rectangle_pumpkin"]
    
    private let viewModel: CardViewModel
    private let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: CardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        
        view.addSubview(someImageView)
        someImageViewConstraints()
        
        view.addSubview(buttonLabel)
        buttonLabelConstraints()
        
        view.addSubview(cameraBackgroundButton)
        cameraButtonConstraints()
        
        view.addSubview(divider)
        dividerConstraints()
        
        view.addSubview(firstColorBackgroundButton)
        firstColorButtonConstraints()
        
        view.addSubview(secondColorBackgroundButton)
        secondColorButtonConstraints()
        
        view.addSubview(thirdColorBackgroundButton)
        thirdColorButtonConstraints()
        
        view.addSubview(fourthColorBackgroundButton)
        fourthColorButtonConstraints()
        
        checkCameraPermission()
        checkAlbumPermission()
        
        input.send(.viewDidLoad)
        bind()
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .getRecentCardBackgroundImgSuccess(let background):
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = background
                        print("CardBackgroundViewController import background image from view Model")
                    })
                case .getRecentCardBackgroundImgFail:
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "Rectangle")
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
    
    lazy var buttonLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemBackground
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 30
        label.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return label
    }()
    
    lazy var cameraBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(systemName: "camera")
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(importImage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var divider: UILabel = {
        let label = UILabel()
        label.backgroundColor = .lightGray
        return label
    }()
    
    lazy var firstColorBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "\(backgroundImageName[0])"), for: .normal)
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if backgroundImageName[0] == "Rectangle" {
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
        if backgroundImageName[1] == "Rectangle" {
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
        if backgroundImageName[2] == "Rectangle" {
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
        if backgroundImageName[3] == "Rectangle" {
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(fourthImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.backgroundColor = .systemBackground
        theImageView.layer.masksToBounds = true
        theImageView.layer.cornerRadius = 50
        theImageView.contentMode = .scaleAspectFill
        return theImageView
    }()
    
    @objc func firstImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("firstImageViewColor clicked")
        guard let image = UIImage(named: "\(backgroundImageName[0])") else { return }
        self.someImageView.image = image
        backgroundImageSend()
    }
    
    @objc func secondImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("secondImageViewColor clicked")
        guard let image = UIImage(named: "\(backgroundImageName[1])") else { return }
        self.someImageView.image = image
        backgroundImageSend()
    }
    
    @objc func thirdImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("secondImageViewColor clicked")
        guard let image = UIImage(named: "\(backgroundImageName[2])") else { return }
        self.someImageView.image = image
        backgroundImageSend()
    }
    
    @objc func fourthImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("fourthImageViewColor clicked")
        guard let image = UIImage(named: "\(backgroundImageName[3])") else { return }
        self.someImageView.image = image
        backgroundImageSend()
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

extension CardBackgroundViewController {
    
    @objc func importImage(_ gesture: UITapGestureRecognizer) {
        var alertStyle = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertStyle = UIAlertController.Style.alert
        }
        let actionSheet = UIAlertController(title: "배경 사진 가져오기", message: nil, preferredStyle: alertStyle)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            DispatchQueue.main.async(execute: {
                self.cameraImagePicker(withType: .camera)
            })
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            DispatchQueue.main.async(execute: {
                self.libraryImagePicker(withType: .photoLibrary)
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            someImageView.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
        backgroundImageSend()
    }
    
    func backgroundImageSend() {
        self.input.send(.setCardBackgroundImg(background: someImageView.image ?? UIImage(systemName: "heart.fill")!))
    }
    
    private func cameraImagePicker(withType type: UIImagePickerController.SourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = type
        pickerController.cameraFlashMode = .off
        pickerController.cameraDevice = .front
        present(pickerController, animated: true)
    }
    
    private func libraryImagePicker(withType type: UIImagePickerController.SourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = type
        present(pickerController, animated: true)
    }
    
    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
            if granted {
                print("Camera: 권한 허용")
            } else {
                print("Camera: 권한 거부")
            }
        })
    }
    
    func checkAlbumPermission() {
        PHPhotoLibrary.requestAuthorization({ status in
            switch status {
            case .authorized:
                print("Album: 권한 허용")
            case .denied:
                print("Album: 권한 거부")
            case .restricted, .notDetermined:
                print("Album: 선택하지 않음")
            default:
                break
            }
        })
    }
}
extension CardBackgroundViewController {
    func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(813)
            make.height.equalTo(515)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    func buttonLabelConstraints() {
        buttonLabel.snp.makeConstraints({ make in
            make.width.equalTo(100)
            make.height.equalTo(450)
            make.leading.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    func cameraButtonConstraints() {
        cameraBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(buttonLabel.snp.top).offset(50)
        })
    }
    
    func dividerConstraints() {
        divider.snp.makeConstraints({ make in
            make.width.equalTo(65)
            make.height.equalTo(2)
            make.centerX.equalTo(cameraBackgroundButton.snp.centerX)
            make.top.equalTo(cameraBackgroundButton.snp.bottom).offset(20)
        })
    }
    
    func firstColorButtonConstraints() {
        firstColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(divider.snp.bottom).offset(20)
        })
    }
    
    func secondColorButtonConstraints() {
        secondColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(firstColorBackgroundButton.snp.bottom).offset(20)
        })
    }
    
    func thirdColorButtonConstraints() {
        thirdColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(secondColorBackgroundButton.snp.bottom).offset(20)
        })
    }
    
    func fourthColorButtonConstraints() {
        fourthColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(thirdColorBackgroundButton.snp.bottom).offset(20)
        })
    }
}
