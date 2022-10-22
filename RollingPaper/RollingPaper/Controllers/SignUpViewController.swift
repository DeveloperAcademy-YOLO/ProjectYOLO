//
//  SignUpViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import UIKit
import Combine
import CombineCocoa
import SnapKit

class SignUpViewController: UIViewController {
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
    private let signInButton: UIButton = {
        let button = UIButton()
        let title = NSAttributedString(string: "로그인", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        button.setAttributedTitle(title, for: .normal)
        return button
    }()
    private let signInDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        view.layer.masksToBounds = true
        return view
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let topOffset = (UIScreen.main.bounds.height - 380) / 2
        emailTextField.snp.updateConstraints({ make in
            make.top.equalToSuperview().offset(topOffset)
        })
        view.layoutIfNeeded()
    }
    
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
    
    private func setSignUpViewUI() {
        view.backgroundColor = .systemBackground
        view.addSubviews([emailTextField, passwordTextField, nameTextField, signInButton, signInDivider, signUpButton])
        let topOffset = (UIScreen.main.bounds.height - 380) / 2
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
        signInButton.snp.makeConstraints({ make in
            make.top.equalTo(nameTextField.snp.top).offset(nameTextField.frame.height + 32)
            make.centerX.equalToSuperview()
        })
        signInDivider.snp.makeConstraints({ make in
            make.top.equalTo(signInButton.snp.bottom).offset(-5.75)
            make.width.equalTo(signInButton.snp.width)
            make.height.equalTo(1)
            make.leading.equalTo(signInButton.snp.leading)
        })
        signUpButton.snp.makeConstraints({ make in
            make.top.equalTo(signInButton.snp.bottom).offset(36)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
            make.height.equalTo(38)
        })
        setCloseButton()
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] receivedValue in
                switch receivedValue {
                case .signUpDidFail(error: let error):
                    self?.handleError(error: error)
                case .signUpDidSuccess:
                    print("Successfully Signed Up")
                }
            })
            .store(in: &cancellables)
        signUpButton
            .tapPublisher
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
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
                    self?.signUpButton.backgroundColor = .systemBlue
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
        signInButton
            .tapPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                if
                    let splitVC = self?.presentingViewController as? SplitViewController,
                    let currentNavVC = splitVC.viewControllers[1] as? UINavigationController {
                    currentNavVC.dismiss(animated: true) {
                        let signInVC = SignInViewController()
                        let navVC = UINavigationController(rootViewController: signInVC)
                        navVC.modalPresentationStyle = .pageSheet
                        splitVC.present(navVC, animated: true)
                    }
                } else {
                    self?.navigationController?.popViewController(animated: true)
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
    
    @objc private func close() {
        dismiss(animated: true)
    }
}

extension SignUpViewController {
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
            signInButton.snp.updateConstraints({ make in
                make.top.equalTo(nameTextField.snp.top).offset(isWaringShown ? nameTextField.frame.height + 32 : 74)
            })
        }
        view.layoutIfNeeded()
    }

    
    @objc private func backgroundDidTap() {
        view.endEditing(true)
        emailTextField.textField.resignFirstResponder()
        passwordTextField.textField.resignFirstResponder()
        nameTextField.textField.resignFirstResponder()
    }
}
