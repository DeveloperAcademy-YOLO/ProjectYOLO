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
    private var cancellabels = Set<AnyCancellable>()
    
    enum Input {
        case signUpButtonDidTap
    }
    enum Output {
        case signInDidFail(error: Error)
        case signUpDidFail(error: Error)
        case emailDidMiss
        case passwordDidMiss
        case ninknameDidMiss
        case signUpDidSuccess
    }
    
    init(authManager: AuthManager = FirebaseAuthManager()) {
        self.authManager = authManager
    }
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input
            .sink { [weak self] receivedValue in
                    guard let self = self else { return }
                switch receivedValue {
                case .signUpButtonDidTap: self.handleSignIn()
                }
            }
            .store(in: &cancellabels)
        return output.eraseToAnyPublisher()
    }
    
    private func handleSignIn() {
        email
            .combineLatest(password, name)
            .map { email, password, name in
                // TODO: Validate email, password, name
                // if not valiadated, then output.send(errors)
                return (email, password, name)
            }
            .map { email, password, name in
                self.authManager
                    .signUp(email: email, password: password, name: name)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] completion in
                switch completion {
                case .finished: print("Successfully signed up")
                case .failure(let error): self?.output.send(.signUpDidFail(error: error))
                }
            } receiveValue: { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.output.send(.signUpDidSuccess)
                }
            }
            .store(in: &cancellabels)
    }
}
