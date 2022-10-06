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
        case emailIsWrong
        case signInDidSuccess
    }
    
    init(authManager: AuthManager = FirebaseAuthManager()) {
        self.authManager = authManager
        bind()
    }
    
    private func bind() {
        authManager
            .socialSignInSubject
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
            .sink { [weak self] receivedValue in
                guard let self = self else { return }
                switch receivedValue {
                case .signInButtonTap: self.handleSignIn()
                case .appleSignInButtonTap: self.authManager.appleSignIn()
                }
            }
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func handleSignIn() {
        email
            .combineLatest(password)
            .map { email, password in
                // TODO: Validate email, password
                // if not valiadated, then output.send(errors)
                return (email, password)
            }
            .map { email, password in
                self.authManager
                    .signIn(email: email, password: password)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { completion in
                switch completion {
                case .finished: print("Successfully signed in")
                case .failure(let error):
                    if let authError = error as? AuthManagerError {
                        self.output.send(.signInDidFail(error: authError))
                    }
                }
            } receiveValue: { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.output.send(.signInDidSuccess)
                }
            }
            .store(in: &cancellables)
    }
}
