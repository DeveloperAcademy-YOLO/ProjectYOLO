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
    }
    
    enum Output {
        case signInDidFail(error: AuthManagerError)
        case emailDidMiss
        case passwordDidMiss
        case signInDidSuccess
    }
    
    init(authManager: AuthManager = FirebaseAuthManager()) {
        self.authManager = authManager
        bind()
    }
    
    private func bind() {
        authManager
            .signedInSubject
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    if let authError = error as? AuthManagerError {
                        self.output.send(.signInDidFail(error: authError))
                    }
                case .finished: print("Successfully Signed In")
                }
            }, receiveValue: { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.output.send(.signInDidSuccess)
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
                }
            })
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func handleText(email: String, password: String) -> (String, String)? {
        let email = email.replacingOccurrences(of: " ", with: "")
        let password = password.replacingOccurrences(of: " ", with: "")
        if email.isEmpty {
            self.output.send(.emailDidMiss)
        }
        if password.isEmpty {
            self.output.send(.passwordDidMiss)
        }
        if !email.isEmpty && !password.isEmpty {
            return (email, password)
        } else {
            return nil
        }
    }
    
    private func handleSignIn() {
        email
            .combineLatest(password)
            .compactMap({ [weak self] email, password in
                // handle email and password validation
                return self?.handleText(email: email, password: password)
            })
            .sink(receiveValue: { [weak self] email, password in
                guard let self = self else { return }
                self.authManager.signIn(email: email, password: password)
            })
            .store(in: &cancellables)
    }
}
