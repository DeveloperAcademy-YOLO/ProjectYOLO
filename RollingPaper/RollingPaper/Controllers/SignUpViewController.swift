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
        textField.setTextFieldType(type: .email)
        return textField
    }()
    private let emailWaringView: WaringView = {
        let waringView = WaringView()
        return waringView
    }()
    private let passwordTextField: SignUpTextField = {
        let textField = SignUpTextField()
        textField.setTextFieldType(type: .password)
        return textField
    }()
    private let passwordWaringView: WaringView = {
        let waringView = WaringView()
        return waringView
    }()
    private let nameTextField: SignUpTextField = {
        let textField = SignUpTextField()
        textField.setTextFieldType(type: .name)
        return textField
    }()
    private let nameWaringView: WaringView = {
        let waringView = WaringView()
        return waringView
    }()
    private let signUpButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.white, for: .normal)
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
        view.addSubviews([emailTextField, emailWaringView, passwordTextField, passwordWaringView, nameTextField, nameWaringView, signUpButton])
        let topOffset = (UIScreen.main.bounds.height - 380) / 2
        emailTextField.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(topOffset)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
            make.height.equalTo(38)
        })
        passwordTextField.snp.makeConstraints({ make in
            make.top.equalTo(emailTextField.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
            make.height.equalTo(38)
        })
        passwordWaringView.snp.makeConstraints({ make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(18)
            make.leading.equalTo(passwordTextField.snp.leading).offset(16)
        })
        nameTextField.snp.makeConstraints({ make in
            make.top.equalTo(passwordWaringView.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
            make.height.equalTo(38)
        })
        nameWaringView.snp.makeConstraints({ make in
            make.top.equalTo(nameTextField.snp.bottom).offset(18)
            make.leading.equalTo(passwordTextField.snp.leading).offset(16)
        })
        signUpButton.snp.makeConstraints({ make in
            make.top.equalTo(nameWaringView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.width.equalTo(380)
            make.height.equalTo(38)
        })
        emailWaringView.showWarning(isShown: false)
        passwordWaringView.showWarning(isShown: false, text: "비밀번호는 6자리 이상이어야 합니다")
        nameWaringView.showWarning(isShown: false, text: "닉네임은 가입 이후에도 수정이 가능합니다")
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receivedValue in
                guard self != nil else { return }
                switch receivedValue {
                case .signInDidFail(error: let error):
                    print(error.localizedDescription)
                case .signUpDidFail(error: let error):
                    print(error.localizedDescription)
                case .emailDidMiss:
                    break
                case .passwordDidMiss:
                    break
                case .ninknameDidMiss:
                    break
                    // alert -> give info to user
                case .signUpDidSuccess:
                    print("Successfully Signed Up")
                    // success -> switch to current view (navigation dismiss, etc...)
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
    }
}
