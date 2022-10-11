//
//  SignUpViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import UIKit
import Combine
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSignUpViewUI()
        bind()
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
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
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
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] receivedValue in
                guard self != nil else { return }
                switch receivedValue {
                case .signUpDidFail(error: let error):
                    break
                case .emailDidMiss:
                    break
                case .passwordDidMiss:
                    break
                case .ninknameDidMiss:
                    break
                case .signUpDidSuccess: break
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
        passwordTextField
            .textField
            .textPublisher
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] password in
                guard let self = self else { return }
                self.viewModel.password.send(password)
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
