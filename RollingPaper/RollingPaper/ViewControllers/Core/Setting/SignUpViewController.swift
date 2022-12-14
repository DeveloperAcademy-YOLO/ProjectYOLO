//
//  SignUpViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Combine
import CombineCocoa
import UIKit
import SnapKit

final class SignUpViewController: UIViewController {
    private let emailTextField: SignUpTextField = {
        let textField = SignUpTextField()
        return textField
    }()
    private let passwordTextField: SignUpTextField = {
        let textField = SignUpTextField()
        return textField
    }()
    private let nameTextField: SignUpTextField = {
        let textField = SignUpTextField()
        return textField
    }()
    private let signUpButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        let title = NSAttributedString(string: "가입", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title3)])
        button.setAttributedTitle(title, for: .normal)
        return button
    }()
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .systemBackground
        return spinner
    }()
    private let viewModel = SignUpViewModel()
    private let input: PassthroughSubject<SignUpViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var currentFocusedTextfieldY: CGFloat = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSignUpViewUI()
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
                self?.spinner.stopAnimating()
                let title = NSAttributedString(string: "가입", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title3)])
                self?.signUpButton.setAttributedTitle(title, for: .normal)
                self?.signUpButton.isUserInteractionEnabled = true
                switch receivedValue {
                case .signUpDidFail(error: let error):
                    self?.handleError(error: error)
                case .signUpDidSuccess:
                    self?.navigateToSignIn()
                }
            })
            .store(in: &cancellables)
        signUpButton
            .tapPublisher
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.signUpButton.setAttributedTitle(nil, for: .normal)
                self.signUpButton.isUserInteractionEnabled = false
                self.spinner.startAnimating()
                self.input.send(.signUpButtonDidTap)
            })
            .store(in: &cancellables)
        emailTextField
            .textField
            .textPublisher
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] email in
                guard let self = self else { return }
                self.viewModel.email.send(email)
            })
            .store(in: &cancellables)
        emailTextField
            .textField
            .didBeginEditingPublisher
            .sink(receiveValue: { [weak self] _ in
                if let yPosition = self?.emailTextField.frame.origin.y {
                    self?.currentFocusedTextfieldY = yPosition
                }
            })
            .store(in: &cancellables)
        emailTextField
            .textField
            .controlPublisher(for: .editingDidEnd)
            .sink(receiveValue: { [weak self] _ in
                self?.emailTextField.textField.resignFirstResponder()
            })
            .store(in: &cancellables)
        emailTextField
            .textField
            .controlPublisher(for: .editingDidEndOnExit)
            .sink(receiveValue: { [weak self] _ in
                self?.emailTextField.textField.resignFirstResponder()
            })
            .store(in: &cancellables)
        passwordTextField
            .textField
            .textPublisher
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] password in
                guard let self = self else { return }
                self.viewModel.password.send(password)
            })
            .store(in: &cancellables)
        passwordTextField
            .textField
            .didBeginEditingPublisher
            .sink(receiveValue: { [weak self] _ in
                if let yPosition = self?.passwordTextField.frame.origin.y {
                    self?.currentFocusedTextfieldY = yPosition
                }
            })
            .store(in: &cancellables)
        passwordTextField
            .textField
            .controlPublisher(for: .editingDidEndOnExit)
            .sink(receiveValue: { [weak self] _ in
                self?.passwordTextField.textField.resignFirstResponder()
            })
            .store(in: &cancellables)
        passwordTextField
            .textField
            .controlPublisher(for: .editingDidEnd)
            .sink(receiveValue: { [weak self] _ in
                self?.passwordTextField.textField.resignFirstResponder()
            })
            .store(in: &cancellables)
        nameTextField
            .textField
            .textPublisher
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] name in
                guard let self = self else { return }
                self.viewModel.name.send(name)
            })
            .store(in: &cancellables)
        nameTextField
            .textField
            .didBeginEditingPublisher
            .sink(receiveValue: { [weak self] _ in
                if let yPosition = self?.nameTextField.frame.origin.y {
                    self?.currentFocusedTextfieldY = yPosition
                }
            })
            .store(in: &cancellables)
        nameTextField
            .textField
            .controlPublisher(for: .editingDidEnd)
            .sink(receiveValue: { [weak self] _ in
                self?.nameTextField.textField.resignFirstResponder()
            })
            .store(in: &cancellables)
        nameTextField
            .textField
            .controlPublisher(for: .editingDidEndOnExit)
            .sink(receiveValue: { [weak self] _ in
                self?.nameTextField.textField.resignFirstResponder()
            })
            .store(in: &cancellables)
        emailTextField.passedSubject
            .combineLatest(passwordTextField.passedSubject, nameTextField.passedSubject)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] passed in
                let (emailPassed, passwordPassed, namePassed) = passed
                if emailPassed && passwordPassed && namePassed {
                    self?.signUpButton.backgroundColor = .label
                    self?.signUpButton.isUserInteractionEnabled = true
                } else {
                    self?.signUpButton.backgroundColor = .systemGray
                    self?.signUpButton.isUserInteractionEnabled = false
                }
            })
            .store(in: &cancellables)
        emailTextField
            .warningShownSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isWaringShown in
                self?.setTextfieldLayout(textFieldType: .email, isWaringShown: isWaringShown)
            })
            .store(in: &cancellables)
        passwordTextField
            .warningShownSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isWaringShown in
                self?.setTextfieldLayout(textFieldType: .password, isWaringShown: isWaringShown)
            })
            .store(in: &cancellables)
        nameTextField
            .warningShownSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isWaringShown in
                self?.setTextfieldLayout(textFieldType: .name, isWaringShown: isWaringShown)
            })
            .store(in: &cancellables)
        let backgroundGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundDidTap))
        view.addGestureRecognizer(backgroundGesture)
    }
    
    private func navigateToSignIn() {
        if let modalPresentingVC = presentingViewController as? SplitViewController {
            modalPresentingVC.dismiss(animated: true) { [weak self] in
                guard
                    let email = self?.viewModel.email.value,
                    let password = self?.viewModel.password.value else { return }
                let signInVC = SignInViewController(email: email, password: password)
                let navVC = UINavigationController(rootViewController: signInVC)
                navVC.modalPresentationStyle = .pageSheet
                modalPresentingVC.present(navVC, animated: true)
            }
        } else {
            postUserInfo()
            print("aaa postUserInfo call from signup")
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func postUserInfo() {
        let email = viewModel.email.value
        let password = viewModel.password.value
        NotificationCenter.default.post(name: .signUpDidSucceed, object: nil, userInfo: ["email": email, "password": password])
    }
    
    private func handleError(error: AuthManagerEnum) {
        switch error {
        case .emailAlreadyInUse:
            emailTextField.setTextFieldState(state: .warning(error: .emailAlreadyInUse))
        case .wrongPassword:
            passwordTextField.setTextFieldState(state: .warning(error: .wrongPassword))
        case .invalidEmail:
            emailTextField.setTextFieldState(state: .warning(error: .invalidEmail))
        case .emailDidMiss:
            emailTextField.setTextFieldState(state: .warning(error: .emailDidMiss))
        case .passwordDidMiss:
            passwordTextField.setTextFieldState(state: .warning(error: .passwordDidMiss))
        case .nameAlreadyInUse:
            nameTextField.setTextFieldState(state: .warning(error: .nameAlreadyInUse))
        case .invalidName:
            nameTextField.setTextFieldState(state: .warning(error: .invalidName))
        default: break
        }
    }
    
    private func setCloseButton() {
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark")?.withTintColor(.black, renderingMode: .alwaysOriginal), style: .done, target: self, action: #selector(close))
        }
    }
    
    @objc private func backgroundDidTap() {
        view.endEditing(true)
        emailTextField.textField.resignFirstResponder()
        passwordTextField.textField.resignFirstResponder()
        nameTextField.textField.resignFirstResponder()
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
}

// extension for keyboard setting
extension SignUpViewController {
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
extension SignUpViewController {
    private func setSignUpViewUI() {
        view.backgroundColor = .systemBackground
        view.addSubviews([emailTextField, passwordTextField, nameTextField, signUpButton])
        signUpButton.addSubview(spinner)
        let topOffset = (view.frame.height - 320) / 2
        emailTextField.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(topOffset)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
        })
        emailTextField.setTextFieldType(type: .email)
        passwordTextField.snp.makeConstraints({ make in
            make.top.equalTo(emailTextField.snp.top).offset(66)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
        })
        passwordTextField.setTextFieldType(type: .password)
        nameTextField.snp.makeConstraints({ make in
            make.top.equalTo(passwordTextField.snp.top).offset(passwordTextField.frame.height + 28)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
        })
        nameTextField.setTextFieldType(type: .name)
        signUpButton.snp.makeConstraints({ make in
            make.top.equalTo(nameTextField.snp.top).offset(nameTextField.frame.height + 32)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
            make.height.equalTo(48)
        })
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        setCloseButton()
    }
    
    private func setTextfieldLayout(textFieldType: SignUpTextField.SignUpTextFieldEnum, isWaringShown: Bool) {
        switch textFieldType {
        case .email:
            passwordTextField.snp.updateConstraints({ make in
                make.top.equalTo(emailTextField.snp.top).offset(isWaringShown ? emailTextField.frame.height + 28 : 66)
            })
        case .password:
            nameTextField.snp.updateConstraints({ make in
                make.top.equalTo(passwordTextField.snp.top).offset(isWaringShown ? passwordTextField.frame.height + 28 : 66)
            })
        case .name:
            signUpButton.snp.updateConstraints({ make in
                make.top.equalTo(nameTextField.snp.top).offset(isWaringShown ? nameTextField.frame.height + 32 : 66)
            })
        }
        view.layoutIfNeeded()
    }

    
    private func layoutIfModalView() {
        if presentingViewController != nil {
            let topOffset = (view.frame.height - 320) / 2
            emailTextField.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(topOffset)
            })
            view.layoutIfNeeded()
        }
    }
}
