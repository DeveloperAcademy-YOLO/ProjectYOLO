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
import AVFoundation
import Photos

class SettingScreenViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    private let viewModel: SettingScreenViewModel = SettingScreenViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let input: PassthroughSubject<SettingScreenViewModel.Input, Never> = .init()
    private var currentFocusedTextfieldY: CGFloat = .zero
    private var countChange: Bool = false
    private var currentImage: UIImage?
    // A URLString -> Data A -> B upload -> C upload -> A upload -> 저장 필요 X
    // Original currentImage UIImage <-> profilePhoto.image
    // Original currentName <-> profileTextField.textField.text
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bind()
        checkAlbumPermission()
    }

    private let editButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.systemBackground
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.setTitle("편집", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.systemBackground
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()

    private let profileImage: UIImageView = {
        let profileImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 180, height: 180))
        profileImage.layer.cornerRadius = profileImage.frame.size.width * 0.5
        profileImage.image = UIImage(named: "person.circle")
        profileImage.contentMode = UIView.ContentMode.scaleAspectFill
        profileImage.backgroundColor = .systemBackground
        profileImage.isUserInteractionEnabled = true
        profileImage.clipsToBounds = true
        return profileImage
    }()

    private let editPhotoButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage(systemName: "photo.on.rectangle.angled"), for: .normal)
        button.tintColor = .white
        button.isHidden = true
        button.isUserInteractionEnabled = true
        return button
    }()

    private func presentImagePicker(withType type: UIImagePickerController.SourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = type
        present(pickerController, animated: true)
    }

    private let profileText: SignUpTextField = {
        let textField = SignUpTextField()
        textField.isHidden = true
        return textField
    }()

    private let profileLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.text = "Guest"
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
        button.backgroundColor = UIColor.systemBackground
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        let title = NSAttributedString(string: "로그아웃", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor: UIColor(rgb: 0x808080)])
        button.setAttributedTitle(title, for: .normal)
        return button
    }()

    private let resignButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.systemBackground
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        let title = NSAttributedString(string: "회원탈퇴", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor: UIColor(rgb: 0xCB0F0F)])
        button.setAttributedTitle(title, for: .normal)
        return button
    }()

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
    
    @objc func logOutBtnPressed(_ gesture: UITapGestureRecognizer) {
            print("cancelBtnPressed")
            let alert = UIAlertController(title: "로그 아웃", message: "로그 아웃 하시겠습니까?", preferredStyle: .alert)
        
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { (_: UIAlertAction!) in
                alert.dismiss(animated: true, completion: nil)
               }))
            
            alert.addAction(UIAlertAction(title: "로그 아웃", style: .destructive, handler: { (_: UIAlertAction!) in
                self.input.send(.signOutDidTap)
               }))
            present(alert, animated: true)
        }
    
    @objc func resignBtnPressed(_ gesture: UITapGestureRecognizer) {
            print("cancelBtnPressed")
            let alert = UIAlertController(title: " 회원 탈퇴를 하면 모든 기록이 사라집니다.", message: "회원 탈퇴를 하시겠습니까?", preferredStyle: .alert)
        
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { (_: UIAlertAction!) in
                alert.dismiss(animated: true, completion: nil)
               }))
            
            alert.addAction(UIAlertAction(title: "회원 탈퇴", style: .destructive, handler: { (_: UIAlertAction!) in
                self.input.send(.resignDidTap)
               }))
            present(alert, animated: true)
        }



    @objc func didCancelButton() {
        profileText.textField.resignFirstResponder()
        navigationItem.rightBarButtonItem?.title = "편집"
        navigationItem.leftBarButtonItem?.title = nil

        divideView.isHidden = false
        logoutButton.isHidden = false
        resignButton.isHidden = false
        profileText.isHidden = true
        visualEffectView.isHidden = true
        editPhotoButton.isHidden = true
        profileLabel.isHidden = false
        profileText.textField.text = self.viewModel.currentUserSubject.value?.name
        profileText.textField.sendActions(for: .editingChanged)
        profileText.setTextFieldType(type: .name)
        profileText.setWaringView(waringShown: false, text: nil)
        profileText.textField.attributedPlaceholder = NSAttributedString(string: self.profileText.textField.text ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)])
        profileImage.image = viewModel.currentPhotoSubject.value ?? UIImage(systemName: "person")
    }

    @objc func didEditButton() {
        if let currentTitle = navigationItem.rightBarButtonItem?.title {
            if currentTitle == "편집" {
                navigationItem.rightBarButtonItem?.title = "저장"
                navigationItem.leftBarButtonItem?.title = "취소"
                divideView.isHidden = true
                logoutButton.isHidden = true
                resignButton.isHidden = true
                profileText.isHidden = false
                visualEffectView.isHidden = false
                editPhotoButton.isHidden = false
                profileLabel.isHidden = true
                profileText.textField.text = self.viewModel.currentUserSubject.value?.name
                profileText.textField.sendActions(for: .editingChanged)
            } else if currentTitle == "저장" {
                profileText.textField.sendActions(for: .editingChanged)
                profileText.textField.sendActions(for: .editingDidEnd)
                if profileText.passedSubject.value {
                    // 이름만 변경
                    // 사진만 변경
                    // 이름, 사진 모두 변경 완료
                    // 이름, 사진 모두 같을 때 -> 아무 것도 인풋으로 send하지 않음
                    
                    if self.profileImage.image == viewModel.currentPhotoSubject.value {
                        // 사진 변경 X
                        if self.viewModel.currentUserSubject.value?.name == self.profileText.textField.text {
                            self.input.send(.userProfileNotSet)
                            // 사진, 이름 변경 X
                        } else {
                            self.input.send(.userNameSet(name: self.profileText.textField.text ?? ""))
                            // 사진 X, 이름 변경 O
                        }
                    } else {
                        // 사진 변경 O
                        guard let image = self.profileImage.image else { return }
                        if self.viewModel.currentUserSubject.value?.name == self.profileText.textField.text {
                            // 사진 변경 O, 이름 변경 X
                            self.input.send(.userImageSet(image: image))
                        } else {
                            // 사진 변경 O, 이름 변경 O
                            self.input.send(.userProfileSet(name: self.profileText.textField.text ?? "", image: image))
                        }
                    }
                }
            }
        }
    }

    @objc private func didBackgroundTap() {
        print("AAA")
        view.endEditing(true)
        profileText.textField.resignFirstResponder()
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if
            let userInfo = notification.userInfo,
            let keyboardInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardInfo.cgRectValue
            let keyboardY = keyboardRect.origin.y
            if currentFocusedTextfieldY + 38 > keyboardY {
                self.view.frame.origin.y =  keyboardY - currentFocusedTextfieldY - 38
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }

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
        view.backgroundColor = .systemBackground
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(didBackgroundTap))
        view.addGestureRecognizer(backgroundTap)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "편집", style: .done, target: self, action: #selector(didEditButton))

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(didCancelButton))

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

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

        profileText.textField.text = viewModel.currentUserSubject.value?.name
        profileText.textField.sendActions(for: .editingChanged)
        profileText.setTextFieldType(type: .name)
        profileText.setWaringView(waringShown: false, text: nil)

        divideView.snp.makeConstraints ({ make in
            make.top.equalTo(profileLabel.snp.bottom).offset(26)
            make.centerX.equalToSuperview()
            make.height.equalTo(2)
            make.width.equalTo(264)
        })

        logoutButton.snp.makeConstraints({ make in
            make.top.equalTo(divideView.snp.bottom).offset(25)
            make.centerX.equalToSuperview()
        })

        resignButton.snp.makeConstraints({ make in
            make.top.equalTo(logoutButton.snp.bottom).offset(16.5)
            make.centerX.equalToSuperview()
        })
    }

    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher()).eraseToAnyPublisher()
        output
            .receive(on: DispatchQueue.main)
            .sink { output in
                switch output {
                case .signOutDidSucceed:
                    if let parentView = self.navigationController?.parent as? SplitViewController {
                        NotificationCenter.default.post(
                            name: Notification.Name.viewChange,
                            object: nil,
                            userInfo: [NotificationViewKey.view: "설정"]
                        )
                    }
                case .userProfileChangeDidSuccess:
                    print("Output Received!")
                    self.countChange = false
                    self.navigationItem.rightBarButtonItem?.title = "편집"
                    self.navigationItem.leftBarButtonItem?.title = nil
                    self.divideView.isHidden = false
                    self.logoutButton.isHidden = false
                    self.resignButton.isHidden = false
                    self.profileText.isHidden = true
                    self.visualEffectView.isHidden = true
                    self.editPhotoButton.isHidden = true
                    self.profileLabel.isHidden = false
                    self.profileText.textField.text = self.viewModel.currentUserSubject.value?.name
                    self.profileText.textField.sendActions(for: .editingChanged)
                    self.profileText.setTextFieldType(type: .name)
                    self.profileText.setWaringView(waringShown: false, text: nil)
                    self.profileText.textField.attributedPlaceholder = NSAttributedString(string: self.profileText.textField.text ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)])
                case .userProfileChangeDidFail:
                    print("Fail")
                    // TODO: Fail 시 alert
                case .nameAlreadyInUse:
                    self.profileText.setTextFieldState(state: .warning(error: .nameAlreadyInUse))
                }
            }
            .store(in: &cancellables)

        editPhotoButton
            .tapPublisher
            .sink { _ in
                self.presentImagePicker(withType: .photoLibrary)
            }
            .store(in: &cancellables)
        
        resignButton.addTarget(self, action: #selector(resignBtnPressed(_:)), for: .touchUpInside)
        
        logoutButton.addTarget(self, action: #selector(logOutBtnPressed(_:)), for: .touchUpInside)
        
        // ViewModel -> current Image, current Photo를 가지고 있다! == AuthManaher에서 구독받는 UserProfileUsbject의 데이터! -> ViewModel에서 해당 데이터 퍼블리셔를 구독하고, 뷰 컨에서 해당 흘러오는 데이터를 구독하기!
        // ViewModel 완료버튼 누르면 -> ViewModel에서 authManager의 setUserProfile 함수 실행해서 현재 데이터와 다른 포토, 이름 넣기 -> AuthManager에서의 데이터 퍼블리셔 값이 변경될 것이기 때문에, 해당 데이터 퍼블리셔 구독하고 있는 ViewModel -> View Controller의 이미지, 이름 등이 자동으로 바뀐다!
        
        profileText
            .textField
            .didBeginEditingPublisher
            .sink { [weak self] _ in
                if let yPosition = self?.profileText.frame.origin.y {
                    self?.currentFocusedTextfieldY = yPosition
                }
            }
            .store(in: &cancellables)
        viewModel.currentUserSubject
            .receive(on: DispatchQueue.main)
            .sink { userModel in
                let placeholder =
                self.profileText.textField.attributedPlaceholder = NSAttributedString(string: userModel?.name ?? "Default", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)])
                self.profileText.textField.text = self.viewModel.currentUserSubject.value?.name
                self.profileText.textField.sendActions(for: .editingChanged)
                self.profileText.textField.sendActions(for: .editingDidEnd)
                self.profileLabel.text = userModel?.name ?? "Guest"
            }
            .store(in: &cancellables)
        viewModel.currentPhotoSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                if let image = image {
                    self?.profileImage.image = image
                } else {
                    self?.profileImage.image = UIImage(systemName: "person")
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAlbumPermission() {
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true) {
            if let image = info[.editedImage] as? UIImage {
                print("hello")
                self.profileImage.image = image
            } else if let image = info[.originalImage] as? UIImage {
                self.countChange = true
                print("original")
                self.profileImage.image = image
            }
        }
    }
}
