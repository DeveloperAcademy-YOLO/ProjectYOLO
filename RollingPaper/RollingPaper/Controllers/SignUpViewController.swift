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
    private let signUpButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        let title = NSAttributedString(string: "가입", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.preferredFont(for: .body, weight: .semibold)])
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
    
    private func setSignUpViewUI() {
        view.backgroundColor = .systemBackground
        view.addSubviews([emailTextField, passwordTextField, nameTextField, signUpButton])
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
        signUpButton.snp.makeConstraints({ make in
            make.top.equalTo(nameTextField.snp.top).offset(passwordTextField.frame.height + 32)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
            make.height.equalTo(38)
        })
    }
    
    private func handleError(error: AuthManagerEnum) {
        switch error {
        case .emailAlreadyInUse:
            emailTextField.setTextFieldState(state: .waring(error: .emailAlreadyInUse))
        case .wrongPassword:
            passwordTextField.setTextFieldState(state: .waring(error: .wrongPassword))
        case .invalidEmail:
            emailTextField.setTextFieldState(state: .waring(error: .invalidEmail))
        case .emailDidMiss:
            emailTextField.setTextFieldState(state: .waring(error: .emailDidMiss))
        case .passwordDidMiss:
            passwordTextField.setTextFieldState(state: .waring(error: .passwordDidMiss))
        case .nameAlreadyInUse:
            nameTextField.setTextFieldState(state: .waring(error: .nameAlreadyInUse))
        case .invalidName:
            nameTextField.setTextFieldState(state: .waring(error: .invalidName))
        default: break
        }
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
            .waringShownSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isWaringShown in
                self?.setTextfieldLayout(textFieldType: .email, isWaringShown: isWaringShown)
            })
            .store(in: &cancellables)
        passwordTextField
            .waringShownSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isWaringShown in
                self?.setTextfieldLayout(textFieldType: .password, isWaringShown: isWaringShown)
            })
            .store(in: &cancellables)
        nameTextField
            .waringShownSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isWaringShown in
                self?.setTextfieldLayout(textFieldType: .name, isWaringShown: isWaringShown)
            })
            .store(in: &cancellables)
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
                make.top.equalTo(nameTextField.snp.top).offset(isWaringShown ? nameTextField.frame.height + 32 : 70)
            })
        }
        view.layoutIfNeeded()
    }
}
