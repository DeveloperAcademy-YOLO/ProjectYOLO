//
//  SingUpViewModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import Combine

final class SignUpViewModel {
    var email = CurrentValueSubject<String, Never>("")
    var password = CurrentValueSubject<String, Never>("")
    var name = CurrentValueSubject<String, Never>("")
    private let authManager: AuthManager
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    enum Input {
        case signUpButtonDidTap
    }
    enum Output {
        case signUpDidFail(error: AuthManagerEnum)
        case signUpDidSuccess
    }
    
    init(authManager: AuthManager = FirebaseAuthManager()) {
        self.authManager = authManager
        bind()
    }
    
    private func bind() {
        authManager
            .signedInSubject
            .sink(receiveValue: { [weak self] receivedValue in
                guard let self = self else { return }
                switch receivedValue {
                case .emailAlreadyInUse:
                    self.output.send(.signUpDidFail(error: .emailAlreadyInUse))
                case .invalidEmail:
                    self.output.send(.signUpDidFail(error: .invalidEmail))
                case .signUpSucceed:
                    self.output.send(.signUpDidSuccess)
                default:
                    self.output.send(.signUpDidFail(error: .unknownError))
                }
            })
            .store(in: &cancellables)
    }
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input
            .sink(receiveValue: { [weak self] receivedValue in
                guard let self = self else { return }
                switch receivedValue {
                case .signUpButtonDidTap: self.handleSignUp()
                }
            })
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func handleSignUp() {
        authManager.signUp(email: email.value, password: password.value, name: name.value)
    }
}
