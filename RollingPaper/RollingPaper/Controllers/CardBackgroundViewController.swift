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

final class CardBackgroundViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        
        view.addSubview(someImageView)
        someImageView.layer.masksToBounds = true
        someImageView.layer.cornerRadius = 50
        someImageView.contentMode = .scaleAspectFill
        someImageViewConstraints()
        
        view.addSubview(buttonLabel)
        buttonLabel.layer.masksToBounds = true
        buttonLabel.layer.cornerRadius = 30
        buttonLabelConstraints()
        
        view.addSubview(photoBackgroundButton)
        cameraButtonConstraints()
        
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
    }
    
    private var backgroundColor: [String] = ["customYellow", "customRed", "customBlack", "darkGray"]
    private var selectedColor = String()

    lazy var buttonLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        return label
    }()
    
    lazy var photoBackgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(systemName: "camera")
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(importImage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var firstColorBackgroundButton: UIButton = {
        let button = UIButton()
        selectedColor = backgroundColor[0]
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.backgroundColor = UIColor(named: selectedColor)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if button.backgroundColor == .white {
            button.layer.borderColor = UIColor.gray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(firstImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var secondColorBackgroundButton: UIButton = {
        let button = UIButton()
        selectedColor = backgroundColor[1]
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.backgroundColor = UIColor(named: selectedColor)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if button.backgroundColor == .white {
            button.layer.borderColor = UIColor.gray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(secondImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var thirdColorBackgroundButton: UIButton = {
        let button = UIButton()
        selectedColor = backgroundColor[2]
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.backgroundColor = UIColor(named: selectedColor)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if button.backgroundColor == .white {
            button.layer.borderColor = UIColor.gray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(thirdImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var fourthColorBackgroundButton: UIButton = {
        let button = UIButton()
        selectedColor = backgroundColor[3]
        button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        button.backgroundColor = UIColor(named: selectedColor)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        if button.backgroundColor == .white {
            button.layer.borderColor = UIColor.gray.cgColor
            button.layer.borderWidth = 2
        }
        button.addTarget(self, action: #selector(fourthImageViewColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.backgroundColor = .white
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        return theImageView
    }()
    
    @objc func firstImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("firstImageViewColor clicked")
        selectedColor = backgroundColor[0]
        someImageView.image = UIImage(named: "Rectangle")?.withTintColor(UIColor(named: selectedColor) ?? UIColor(red: 100, green: 200, blue: 200), renderingMode: .alwaysOriginal)
    }
    
    @objc func secondImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("secondImageViewColor clicked")
        selectedColor = backgroundColor[1]
        someImageView.image = UIImage(named: "Rectangle")?.withTintColor(UIColor(named: selectedColor) ?? UIColor(red: 100, green: 200, blue: 200), renderingMode: .alwaysOriginal)
    }
    
    @objc func thirdImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("thirdImageViewColor clicked")
        selectedColor = backgroundColor[2]
        someImageView.image = UIImage(named: "Rectangle")?.withTintColor(UIColor(named: selectedColor) ?? UIColor(red: 100, green: 200, blue: 200), renderingMode: .alwaysOriginal)
    }
    
    @objc func fourthImageViewColor(_ gesture: UITapGestureRecognizer) {
        print("fourthImageViewColor clicked")
        selectedColor = backgroundColor[3]
        someImageView.image = UIImage(named: "Rectangle")?.withTintColor(UIColor(named: selectedColor) ?? UIColor(red: 100, green: 200, blue: 200), renderingMode: .alwaysOriginal)
    }
    
    @objc func importImage(_ gesture: UITapGestureRecognizer) {
        var alertStyle = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertStyle = UIAlertController.Style.alert
        }
        let actionSheet = UIAlertController(title: "배경 사진 가져오기", message: nil, preferredStyle: alertStyle)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            DispatchQueue.main.async(execute: {
                self.presentImagePicker(withType: .camera)
            })
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            DispatchQueue.main.async(execute: {
                self.presentImagePicker(withType: .photoLibrary)
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
    }
    
    private func presentImagePicker(withType type: UIImagePickerController.SourceType) {
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
            make.width.equalTo(250)
            make.height.equalTo(450)
            make.leading.equalTo(-160)
            make.centerY.equalTo(self.view)
        })
    }
    
    func cameraButtonConstraints() {
        photoBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.top.equalTo(buttonLabel.snp.top).offset(50)
        })
    }
    
    func firstColorButtonConstraints() {
        firstColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.top.equalTo(photoBackgroundButton.snp.bottom).offset(20)
        })
    }
    
    func secondColorButtonConstraints() {
        secondColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.top.equalTo(firstColorBackgroundButton.snp.bottom).offset(20)
        })
    }
    
    func thirdColorButtonConstraints() {
        thirdColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.top.equalTo(secondColorBackgroundButton.snp.bottom).offset(20)
        })
    }
    
    func fourthColorButtonConstraints() {
        fourthColorBackgroundButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.top.equalTo(thirdColorBackgroundButton.snp.bottom).offset(20)
        })
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
