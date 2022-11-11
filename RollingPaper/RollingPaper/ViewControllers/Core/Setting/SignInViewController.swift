//
//  SignInViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import AuthenticationServices
import Combine
import CombineCocoa
import SnapKit
import UIKit

final class SignInViewController: UIViewController {
    enum TextFieldFocused {
        case normal
        case emailFocused
        case emailWaring
        case passwordFocused
        case passwordWaring
        case bothWaring
    }
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "logo")
        return imageView
    }()
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.attributedPlaceholder = NSAttributedString(string: "이메일 주소", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)])
        textField.textContentType = .emailAddress
        textField.font = .preferredFont(forTextStyle: .body)
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: textField.frame.height))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: textField.frame.height))
        textField.rightView = rightPaddingView
        textField.rightViewMode = .always
        return textField
    }()
    private let emailClearButton: UIButton = {
        let button = UIButton()
        button.setImage(systemName: "x.circle.fill")
        button.tintColor = .systemGray4
        return button
    }()
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.attributedPlaceholder = NSAttributedString(string: "비밀번호", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)])
        textField.font = .preferredFont(forTextStyle: .body)
        textField.textContentType = .oneTimeCode
        textField.isSecureTextEntry = false
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: textField.frame.height))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: textField.frame.height))
        textField.rightView = rightPaddingView
        textField.rightViewMode = .always
        return textField
    }()
    private let passwordClearButton: UIButton = {
        let button = UIButton()
        button.setImage(systemName: "x.circle.fill")
        button.tintColor = .systemGray4
        return button
    }()
    private let signUpButton: UIButton = {
        let button = UIButton()
        let title = NSAttributedString(string: "계정 만들기", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        button.setAttributedTitle(title, for: .normal)
        return button
    }()
    private let signUpDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        view.layer.masksToBounds = true
        return view
    }()
    private let signInButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 12
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 10
        let title = NSAttributedString(string: "로그인", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title3), NSAttributedString.Key.foregroundColor: UIColor.label])
        button.setAttributedTitle(title, for: .normal)
        return button
    }()
    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray
        view.layer.masksToBounds = true
        return view
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
        label.font = .preferredFont(forTextStyle: .body)
        label.isHidden = true
        return label
    }()
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .label
        return spinner
    }()
    private let viewModel = SignInViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let input: PassthroughSubject<SignInViewModel.Input, Never> = .init()
    private var currentFocusedTextfieldY: CGFloat = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        setSignInViewUI()
        bind()
        setKeyboardObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        layoutIfModalView()
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] receivedValue in
                guard let self = self else { return }
                let title = NSAttributedString(string: "로그인", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title3), NSAttributedString.Key.foregroundColor: UIColor.label])
                self.signInButton.isUserInteractionEnabled = true
                self.signInButton.setAttributedTitle(title, for: .normal)
                self.spinner.stopAnimating()
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
                    self.navigateToCurrentFlow()
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
                self?.signInButton.isUserInteractionEnabled = false
                self?.signInButton.setAttributedTitle(nil, for: .normal)
                self?.spinner.isHidden = false
                self?.spinner.startAnimating()
            })
            .store(in: &cancellables)
        appleSignInButton
            .controlEventPublisher(for: .touchDown)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.appleSignInButtonTap)
            })
            .store(in: &cancellables)
        emailTextField
            .controlPublisher(for: .editingChanged)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.emailFocused)
                self?.spinner.isHidden = true
            })
            .store(in: &cancellables)
        emailTextField
            .textPublisher
            .sink(receiveValue: { [weak self] email in
                guard
                    let email = email,
                    !email.isEmpty else {
                    self?.emailClearButton.isHidden = true
                    return
                }
                self?.viewModel.email.send(email)
                self?.emailClearButton.isHidden = false
            })
            .store(in: &cancellables)
        emailTextField
            .didBeginEditingPublisher
            .sink(receiveValue: { [weak self] _ in
                if let yPosition = self?.emailTextField.frame.origin.y {
                    self?.currentFocusedTextfieldY = yPosition
                }
            })
            .store(in: &cancellables)
        passwordTextField
            .controlPublisher(for: .editingChanged)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.passwordFocused)
            })
            .store(in: &cancellables)
        passwordTextField
            .didBeginEditingPublisher
            .sink(receiveValue: { [weak self] _ in
                if let yPosition = self?.passwordTextField.frame.origin.y {
                    self?.currentFocusedTextfieldY = yPosition
                }
                self?.passwordTextField.isSecureTextEntry = true
            })
            .store(in: &cancellables)
        passwordTextField
            .textPublisher
            .sink(receiveValue: { [weak self] password in
                guard
                    let password = password,
                    !password.isEmpty else {
                    self?.passwordClearButton.isHidden = true
                    return
                }
                self?.viewModel.password.send(password)
                self?.passwordClearButton.isHidden = false
            })
            .store(in: &cancellables)
        emailTextField
            .controlPublisher(for: .editingDidEnd)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.normalBoundTap)
                self?.emailTextField.resignFirstResponder()
            })
            .store(in: &cancellables)
        emailTextField
            .controlPublisher(for: .editingDidEndOnExit)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.normalBoundTap)
                self?.emailTextField.resignFirstResponder()
            })
            .store(in: &cancellables)
        passwordTextField
            .controlPublisher(for: .editingDidEnd)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.normalBoundTap)
                self?.passwordTextField.resignFirstResponder()
            })
            .store(in: &cancellables)
        passwordTextField
            .controlPublisher(for: .editingDidEndOnExit)
            .sink(receiveValue: { [weak self] _ in
                self?.input.send(.normalBoundTap)
                self?.passwordTextField.resignFirstResponder()
            })
            .store(in: &cancellables)
        emailClearButton
            .tapPublisher
            .sink { [weak self] _ in
                self?.emailTextField.text = ""
                self?.emailTextField.sendActions(for: .editingChanged)
            }
            .store(in: &cancellables)
        passwordClearButton
            .tapPublisher
            .sink { [weak self] _ in
                self?.passwordTextField.text = ""
                self?.passwordTextField.sendActions(for: .editingChanged)
            }
            .store(in: &cancellables)
        signUpButton
            .tapPublisher
            .sink(receiveValue: { [weak self] _ in
                if
                    let splitVC = self?.presentingViewController as? SplitViewController,
                    let currentNavVC = splitVC.viewControllers[1] as? UINavigationController {
                    currentNavVC.dismiss(animated: true) {
                        let signUpVC = SignUpViewController()
                        let navVC = UINavigationController(rootViewController: signUpVC)
                        navVC.modalPresentationStyle = .formSheet
                        splitVC.present(navVC, animated: true)
                    }
                } else {
                    let backButtonItem = UIBarButtonItem(title: "로그인", style: .plain, target: self, action: nil)
                    backButtonItem.tintColor = .systemGray
                    self?.navigationItem.backBarButtonItem = backButtonItem
                    self?.navigationController?.pushViewController(SignUpViewController(), animated: true)
                }
            })
            .store(in: &cancellables)
        let backgroundGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundDidTap))
        view.addGestureRecognizer(backgroundGesture)
    }
    
    private func setCloseButton() {
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark")?.withTintColor(.black, renderingMode: .alwaysOriginal), style: .done, target: self, action: #selector(close))
        }
    }
    
    private func handleError(error: AuthManagerEnum) {
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
            setWarningMessage(isShown: false, message: nil)
            setTextFieldUI(textFieldFocused: .normal)
        }
    }
        
    private func navigateToCurrentFlow() {
        if let modalPresentingVC = presentingViewController as? SplitViewController {
            if
                let currentNavVC = modalPresentingVC.viewControllers[1] as? UINavigationController,
                let currentVC = currentNavVC.viewControllers.last as? WrittenPaperViewController {
                dismiss(animated: true)
            }
        } else {
            if
                let currentNavVC = navigationController,
                let currentVC = currentNavVC.viewControllers.last as? SignInViewController {
                NotificationCenter.default.post(name: .viewChange, object: nil, userInfo: [NotificationViewKey.view: "설정"])
            }
        }
    }
    
    @objc private func backgroundDidTap() {
        view.endEditing(true)
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
}

// extension for keyboard setting
extension SignInViewController {
    private func setKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if
            let userInfo = notification.userInfo,
            let keyboardInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardInfo.cgRectValue
            let keyboardY = keyboardRect.origin.y
            let originalHeight = UIScreen.main.bounds.height
            let currentViewHeight = view.frame.height
            let offsetHeight = (originalHeight - currentViewHeight) / 2
            if currentFocusedTextfieldY + offsetHeight + 38 > keyboardY {
                view.frame.origin.y = keyboardY - currentFocusedTextfieldY - 38 - offsetHeight
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
}


// extension for SnapKit
extension SignInViewController {
    private func setSignInViewUI() {
        view.backgroundColor = .systemBackground
        view.addSubviews([logoImageView, emailTextField, passwordTextField, waringImage, waringLabel, signUpButton, signUpDivider, signInButton, divider, appleSignInButton])
        signInButton.addSubview(spinner)
        emailTextField.addSubview(emailClearButton)
        passwordTextField.addSubview(passwordClearButton)
        let topOffset = (view.frame.height - 332 + 85 + 72) / 2
        logoImageView.snp.makeConstraints({ make in
            make.width.equalTo(120)
            make.height.equalTo(85)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(emailTextField.snp.top).offset(-72)
        })
        emailTextField.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(topOffset)
            make.centerX.equalToSuperview()
            make.height.equalTo(38)
            make.width.equalTo(380)
        })
        emailClearButton.snp.makeConstraints({ make in
            make.width.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-11)
        })
        passwordTextField.snp.makeConstraints({ make in
            make.top.equalTo(emailTextField.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.height.equalTo(38)
            make.width.equalTo(380)
        })
        passwordClearButton.snp.makeConstraints({ make in
            make.width.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-11)
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
        signUpButton.snp.makeConstraints({ make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(36)
            make.centerX.equalToSuperview()
        })
        signUpDivider.snp.makeConstraints({ make in
            make.top.equalTo(signUpButton.snp.bottom).offset(-5.75)
            make.width.equalTo(signUpButton.snp.width)
            make.height.equalTo(1)
            make.leading.equalTo(signUpButton.snp.leading)
        })
        signInButton.snp.makeConstraints({ make in
            make.top.equalTo(signUpButton.snp.bottom).offset(36)
            make.width.equalTo(375)
            make.height.equalTo(48)
            make.centerX.equalToSuperview()
        })
        divider.snp.makeConstraints({ make in
            make.width.equalTo(340)
            make.height.equalTo(2)
            make.top.equalTo(signInButton.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        })
        appleSignInButton.snp.makeConstraints({ make in
            make.top.equalTo(divider.snp.bottom).offset(24)
            make.width.equalTo(375)
            make.height.equalTo(48)
            make.centerX.equalToSuperview()
        })
        spinner.snp.makeConstraints({ make in
            make.center.equalToSuperview()
            make.height.width.equalTo(40)
        })
        setCloseButton()
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
            emailTextField.layer.borderColor = UIColor.systemBlue.cgColor
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
            passwordTextField.layer.borderColor = UIColor.systemBlue.cgColor
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
    
    private func setWarningMessage(isShown: Bool, message: String?) {
        waringLabel.isHidden = !isShown
        waringImage.isHidden = !isShown
        if let message = message {
            waringLabel.text = message
        }
        signUpButton.snp.updateConstraints({ make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(isShown ? 69 : 36)
        })
        view.layoutIfNeeded()
    }
    
    private func layoutIfModalView() {
        if presentingViewController != nil {
            let topOffset = (view.frame.height - 332 + 85 + 72) / 2
            emailTextField.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(topOffset)
            })
            view.layoutIfNeeded()
        }
    }
}
