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
    private let emailTextField: UITextField = {
        let textField = UITextField()
        return textField
    }()
    private let emailWaringView: WaringView = {
        let waringView = WaringView()
        return waringView
    }()
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        return textField
    }()
    private let passwordWaringView: WaringView = {
        let waringView = WaringView()
        return waringView
    }()
    private let nameTextField: UITextField = {
        let textField = UITextField()
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
        bind()
    }
    
    private func setSignUpViewUI() {
        view.backgroundColor = .systemBackground
        view.addSubviews([emailTextField, emailWaringView, passwordTextField, passwordWaringView, nameTextField, nameWaringView, signUpButton])
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
        nameTextField
            .textPublisher
            .compactMap({ $0 })
            .sink { [weak self] name in
                guard let self = self else { return }
                self.viewModel.name.send(name)
            }
            .store(in: &cancellables)
    }
}
