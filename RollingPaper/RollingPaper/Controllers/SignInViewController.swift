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
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.layer.cornerRadius = 12
        textField.borderRect(forBounds: <#T##CGRect#>)
        return textField
    }()
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        return textField
    }()
    private let signInButton: UIButton = {
        let button = UIButton()
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.background.backgroundColor = .systemBlue
            button.configuration = config
        } else {
            // Fallback on earlier versions
            button.backgroundColor = .systemBlue
        }
        button.setTitle("Sign In", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    private let appleSignInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        return button
    }()
    private let waringImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    private let waringLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
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
        view.addSubviews([emailTextField, passwordTextField, signInButton, appleSignInButton])
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
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] receivedValue in
                guard self != nil else { return }
                switch receivedValue {
                case .signInDidFail(error: let error):
                    print(error.localizedDescription)
                case .emailDidMiss:
                    break
                case .passwordDidMiss:
                    break
                // Set alert if not validated
                case .signInDidSuccess:
                    print("Successfully Signed In")
                // Success -> Into current view flows...
                }
            })
            .store(in: &cancellables)
        signInButton
            .tapPublisher
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.input.send(.signInButtonTap)
            })
            .store(in: &cancellables)
        appleSignInButton
            .controlPublisher(for: .touchUpInside)        
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.input.send(.appleSignInButtonTap)
            })
            .store(in: &cancellables)
        emailTextField
            .textPublisher
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] email in
                guard let self = self else { return }
                self.viewModel.email.send(email)
            })
            .store(in: &cancellables)
        passwordTextField
            .textPublisher
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] password in
                guard let self = self else { return }
                self.viewModel.password.send(password)
            })
            .store(in: &cancellables)
    }
}
