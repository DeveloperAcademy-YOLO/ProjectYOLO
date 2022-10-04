//
//  AuthManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import FirebaseAuth
import Combine

protocol AuthManager {
    func signIn(email: String, password: String) -> AnyPublisher<Bool, Error>
    func signUp(email: String, password: String, name: String) -> AnyPublisher<Bool, Error>
}

final class FirebaseAuthManager: AuthManager {
    func signUp(email: String, password: String, name: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            self?.auth.createUser(withEmail: email, password: password, completion: { result, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            })
        }
        .eraseToAnyPublisher()
    }
                                  
    private let auth = FirebaseAuth.Auth.auth()
    func signIn(email: String, password: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            self?.auth.signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
