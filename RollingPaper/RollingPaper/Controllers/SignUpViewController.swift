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
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let topOffset = (UIScreen.main.bounds.height - 380) / 2
        emailTextField.snp.updateConstraints({ make in
            make.top.equalToSuperview().offset(topOffset)
        })
        view.layoutIfNeeded()
    }
    
    private func setSignUpViewUI() {
        view.backgroundColor = .systemBackground
        view.addSubviews([emailTextField, passwordTextField])
        let topOffset = (UIScreen.main.bounds.height - 380) / 2
        emailTextField.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(topOffset)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
        })
        emailTextField.setTextFieldType(type: .email)
        passwordTextField.snp.makeConstraints({ make in
            make.top.equalTo(emailTextField.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
        })
        passwordTextField.setTextFieldType(type: .password)
//        nameTextField.snp.makeConstraints({ make in
//            make.top.equalTo(passwordTextField.snp.bottom).offset(28)
//            make.centerX.equalToSuperview()
//            make.width.equalTo(380)
//        })
//        signUpButton.snp.makeConstraints({ make in
//            make.top.equalTo(nameTextField.snp.bottom).offset(32)
//            make.centerX.equalToSuperview()
//            make.width.equalTo(380)
//            make.height.equalTo(38)
//        })
//        emailTextField.setTextFieldType(type: .email)
//        passwordTextField.setTextFieldType(type: .password)
//        nameTextField.setTextFieldType(type: .name)
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receivedValue in
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
            }
            .store(in: &cancellables)
        signUpButton
            .tapPublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.input.send(.signUpButtonDidTap)
            }
            .store(in: &cancellables)
        
        emailTextField
            .textField
            .textPublisher
            .compactMap({ $0 })
            .sink { [weak self] email in
                guard let self = self else { return }
                self.viewModel.email.send(email)
            }
            .store(in: &cancellables)
        passwordTextField
            .textField
            .textPublisher
            .compactMap({ $0 })
            .sink { [weak self] password in
                guard let self = self else { return }
                self.viewModel.password.send(password)
            }
            .store(in: &cancellables)
        nameTextField
            .textField
            .textPublisher
            .compactMap({ $0 })
            .sink { [weak self] name in
                guard let self = self else { return }
                self.viewModel.name.send(name)
            }
            .store(in: &cancellables)
        nameTextField
            .textField.controlPublisher(for: .editingDidEnd)
    }
}
