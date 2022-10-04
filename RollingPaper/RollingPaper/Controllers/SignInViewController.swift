//
//  SignInViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import UIKit
import Combine
import CombineCocoa
import SnapKit

class SignInViewController: UIViewController {
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "Email"
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        return textField
    }()
    private let passwordLabel: UILabel = {
        let label = UILabel()
        label.text = "Password"
        label.font = .preferredFont(forTextStyle: .headline)
        return label
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
        // TODO: auto layout using snapkit
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordLabel)
        view.addSubview(passwordTextField)
        view.addSubview(signInButton)
        emailLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
        emailLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        emailTextField.topAnchor.constraint(equalTo: emailLabel.topAnchor).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: emailLabel.trailingAnchor, constant: 20).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        passwordLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 30).isActive = true
        passwordLabel.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: passwordLabel.topAnchor).isActive = true
        passwordTextField.leadingAnchor.constraint(equalTo: passwordLabel.trailingAnchor, constant: 20).isActive = true
        passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        signInButton.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 30).isActive = true
        signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        // TODO: relayout -> fit as HI-FI
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
                case .emailDidMiss:
                    break
                case .passwordDidMiss:
                    break
                // Set alert if not validated
                case .signInDidSuccess:
                    print("Successfully Signed In")
                // Success -> Into current view flows...
                }
            }
            .store(in: &cancellables)
        signInButton
            .tapPublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.input.send(.signInButtonTap)
            }
            .store(in: &cancellables)
        
        emailTextField
            .textPublisher
            .compactMap({ $0 })
            .sink { [weak self] email in
                guard let self = self else { return }
                self.viewModel.email.send(email)
            }
            .store(in: &cancellables)
        passwordTextField
            .textPublisher
            .compactMap({ $0 })
            .sink { [weak self] password in
                guard let self = self else { return }
                self.viewModel.password.send(password)
            }
            .store(in: &cancellables)
    }
}
