//
//  SignInViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import UIKit
import Combine
import SnapKit
import AuthenticationServices

class SignInViewController: UIViewController {
    enum TextFieldFocused {
        case normal
        case emailFocused
        case emailWaring
        case passwordFocused
        case passwordWaring
        case bothWaring
    }
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.attributedPlaceholder = NSAttributedString(string: "이메일 주소", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.attributedPlaceholder = NSAttributedString(string: "비밀번호", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        textField.isSecureTextEntry = true
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    private let signInButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(rgb: 0x007AFF)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.setTitle("로그인", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    private let appleSignInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 12
        return button
    }()
    private let waringImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.image = UIImage(systemName: "exclamationmark.bubble.fill")?.withTintColor(UIColor(rgb: 0xFF3B30), renderingMode: .alwaysOriginal)
        imageView.isHidden = true
        return imageView
    }()
    private let waringLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.isHidden = true
        return label
    }()
    
    private let viewModel = SignInViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let input: PassthroughSubject<SignInViewModel.Input, Never> = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        setSignInViewUI()
        bind()
    }
    
    private func setSignInViewUI() {
        view.backgroundColor = .systemBackground
        view.addSubviews([emailTextField, passwordTextField, waringImage, waringLabel, signInButton, appleSignInButton])
        emailTextField.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset((view.frame.height - 246) / 2)
            make.centerX.equalToSuperview()
            make.height.equalTo(38)
            make.width.equalTo(380)
        })
        passwordTextField.snp.makeConstraints({ make in
            make.top.equalTo(emailTextField.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.height.equalTo(38)
            make.width.equalTo(380)
        })
        waringImage.snp.makeConstraints({ make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(19)
            make.leading.equalTo(passwordTextField.snp.leading).offset(16)
            make.height.equalTo(21.52)
            make.width.equalTo(21.57)
        })
        waringLabel.snp.makeConstraints({ make in
            make.top.equalTo(waringImage.snp.top)
            make.leading.equalTo(waringImage.snp.trailing).offset(11.48)
        })
        signInButton.snp.makeConstraints({ make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(28)
            make.width.equalTo(380)
            make.height.equalTo(48)
            make.centerX.equalToSuperview()
        })
        appleSignInButton.snp.makeConstraints({ make in
            make.top.equalTo(signInButton.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.width.equalTo(380)
        })
    }
    
    private func handleError(error: AuthManagerError) {
        switch error {
        case .userNotFound:
            setWarningMessage(isShown: true, message: "이메일이 존재하지 않습니다")
            setTextFieldUI(textFieldFocused: .emailWaring)
        case .userTokenExpired:
            setWarningMessage(isShown: true, message: "이메일 토큰이 만료되었습니다")
            setTextFieldUI(textFieldFocused: .emailWaring)
        case .emailAlreadyInUse:
            setWarningMessage(isShown: true, message: "이미 사용 중인 이메일입니다")
            setTextFieldUI(textFieldFocused: .emailWaring)
        case .wrongPassword:
            setWarningMessage(isShown: true, message: "비밀번호가 틀렸습니다")
            setTextFieldUI(textFieldFocused: .passwordWaring)
        case .invalidEmail:
            setWarningMessage(isShown: true, message: "입력된 이메일 주소를 확인해주세요")
            setTextFieldUI(textFieldFocused: .emailWaring)
        case .unknownError:
            setWarningMessage(isShown: true, message: "알 수 없는 오류입니다")
            setTextFieldUI(textFieldFocused: .bothWaring)
        default:
            setWarningMessage(isShown: true, message: "알 수 없는 오류입니다")
            setTextFieldUI(textFieldFocused: .bothWaring)
        }
    }
    
    private func setWarningMessage(isShown: Bool, message: String?) {
        waringLabel.isHidden = !isShown
        waringImage.isHidden = !isShown
        if let message = message {
            waringLabel.text = message
        }
        signInButton.snp.updateConstraints({ make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(isShown ? 80 : 28)
        })
        view.layoutIfNeeded()
    }
    
    private func setTextFieldUI(textFieldFocused: TextFieldFocused) {
        switch textFieldFocused {
        case .normal:
            emailTextField.layer.borderWidth = 1.0
            emailTextField.layer.borderColor = UIColor.systemGray.cgColor
            passwordTextField.layer.borderWidth = 1.0
            passwordTextField.layer.borderColor = UIColor.systemGray.cgColor
        case .emailFocused:
            emailTextField.layer.borderWidth = 2.0
            emailTextField.layer.borderColor = UIColor.systemGray.cgColor
            passwordTextField.layer.borderWidth = 1.0
            passwordTextField.layer.borderColor = UIColor.systemGray.cgColor
        case .emailWaring:
            emailTextField.layer.borderWidth = 2.0
            emailTextField.layer.borderColor = UIColor.systemRed.cgColor
            passwordTextField.layer.borderWidth = 1.0
            passwordTextField.layer.borderColor = UIColor.systemGray.cgColor
        case .passwordFocused:
            emailTextField.layer.borderWidth = 1.0
            emailTextField.layer.borderColor = UIColor.systemGray.cgColor
            passwordTextField.layer.borderWidth = 2.0
            passwordTextField.layer.borderColor = UIColor.systemGray.cgColor
        case .passwordWaring:
            emailTextField.layer.borderWidth = 1.0
            emailTextField.layer.borderColor = UIColor.systemGray.cgColor
            passwordTextField.layer.borderWidth = 2.0
            passwordTextField.layer.borderColor = UIColor.systemRed.cgColor
        case .bothWaring:
            emailTextField.layer.borderWidth = 2.0
            emailTextField.layer.borderColor = UIColor.systemRed.cgColor
            passwordTextField.layer.borderWidth = 2.0
            passwordTextField.layer.borderColor = UIColor.systemRed.cgColor
        }
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] receivedValue in
                guard let self = self else { return }
                switch receivedValue {
                case .signInDidFail(error: let error): self.handleError(error: error)
                case .emailDidMiss:
                    self.setWarningMessage(isShown: true, message: "이메일을 입력해주세요")
                    self.setTextFieldUI(textFieldFocused: .emailWaring)
                case .passwordDidMiss:
                    self.setWarningMessage(isShown: true, message: "비밀번호를 입력해주세요")
                    self.setTextFieldUI(textFieldFocused: .passwordWaring)
                case .signInDidSuccess:
                    self.setWarningMessage(isShown: false, message: nil)
                    // navigate to current view flow (dismiss, etc...)
                case .emailFocused:
                    self.setWarningMessage(isShown: false, message: nil)
                    self.setTextFieldUI(textFieldFocused: .emailFocused)
                case .passwordFocused:
                    self.setWarningMessage(isShown: false, message: nil)
                    self.setTextFieldUI(textFieldFocused: .passwordFocused)
                case .normalBoundTap:
                    self.setTextFieldUI(textFieldFocused: .normal)
                }
            })
            .store(in: &cancellables)
        signInButton
            .tapPublisher
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.signInButtonTap)
            })
            .store(in: &cancellables)
        appleSignInButton
            .controlPublisher(for: .touchUpInside)        
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.appleSignInButtonTap)
            })
            .store(in: &cancellables)
        emailTextField
            .controlPublisher(for: .editingDidBegin)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.emailFocused)
            })
            .store(in: &cancellables)
        emailTextField
            .textPublisher
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] email in
                self?.viewModel.email.send(email)
            })
            .store(in: &cancellables)
        passwordTextField
            .controlPublisher(for: .editingDidBegin)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.passwordFocused)
            })
            .store(in: &cancellables)
        passwordTextField
            .textPublisher
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] password in
                self?.viewModel.password.send(password)
            })
            .store(in: &cancellables)
        emailTextField
            .controlPublisher(for: .editingDidEnd)
            .combineLatest(passwordTextField.controlPublisher(for: .editingDidEnd))
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.normalBoundTap)
            })
            .store(in: &cancellables)
    }
}
