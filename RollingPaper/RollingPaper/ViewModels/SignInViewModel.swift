//
//  SignInViewModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import Combine
import SnapKit

final class SignInViewModel {
    var email = CurrentValueSubject<String, Never>("")
    var password = CurrentValueSubject<String, Never>("")
    private let authManager: AuthManager
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    enum Input {
        case signInButtonTap
        case appleSignInButtonTap
        case emailFocused
        case passwordFocused
        case normalBoundTap
    }
    
    enum Output {
        case signInDidFail(error: AuthManagerEnum)
        case emailDidMiss
        case passwordDidMiss
        case signInDidSuccess
        case emailFocused
        case passwordFocused
        case normalBoundTap
    }
    
    init(authManager: AuthManager = FirebaseAuthManager.shared) {
        self.authManager = authManager
        bind()
    }
    
    private func bind() {
        authManager
            .signedInSubject
            .sink(receiveValue: { [weak self] receivedValue in
                guard let self = self else { return }
                if receivedValue == .signInSucceed {
                    self.output.send(.signInDidSuccess)
                } else {
                    self.output.send(.signInDidFail(error: receivedValue))
                }
            })
            .store(in: &cancellables)
    }
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input
            .sink(receiveValue: { [weak self] receivedValue in
                guard let self = self else { return }
                switch receivedValue {
                case .signInButtonTap: self.handleSignIn()
                case .appleSignInButtonTap: self.authManager.appleSignIn()
                case .emailFocused:
                    self.output.send(.emailFocused)
                case .passwordFocused:
                    self.output.send(.passwordFocused)
                case .normalBoundTap: self.output.send(.normalBoundTap)
                }
            })
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func handleText(email: String, password: String) -> (String, String)? {
        let email = email.replacingOccurrences(of: " ", with: "")
        let password = password.replacingOccurrences(of: " ", with: "")
        if password.isEmpty {
            self.output.send(.passwordDidMiss)
            return nil
        }
        if email.isEmpty {
            self.output.send(.emailDidMiss)
            return nil
        }
        if !email.isEmpty && !password.isEmpty {
            return (email, password)
        } else {
            return nil
        }
    }
    
    private func handleSignIn() {
        if let (email, password) = handleText(email: email.value, password: password.value) {
            authManager.signIn(email: email, password: password)
        }
    }
}
