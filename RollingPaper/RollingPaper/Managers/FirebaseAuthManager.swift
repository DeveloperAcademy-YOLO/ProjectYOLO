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
    func signOut() -> AnyPublisher<Bool, Error>
    func deleteUser() -> AnyPublisher<Bool, Error>
    func updateUserProfile(name: String?, photoURLString: String?) -> AnyPublisher<Bool, Error>
}

final class FirebaseAuthManager: AuthManager {
    private let auth = FirebaseAuth.Auth.auth()
    
    enum AuthError: LocalizedError {
        case userNotExists
    }
    
    func signUp(email: String, password: String, name: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            self?.auth.createUser(withEmail: email, password: password, completion: { _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            })
        }
        .eraseToAnyPublisher()
    }
                                  
    func signIn(email: String, password: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            self?.auth.signIn(withEmail: email, password: password) { _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            do {
                try self?.auth.signOut()
                promise(.success(true))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteUser() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            if let user = self?.auth.currentUser {
                user.delete { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(true))
                    }
                }
            } else {
                promise(.failure(AuthError.userNotExists))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateUserProfile(name: String? = nil, photoURLString: String? = nil) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            if let user = self?.auth.currentUser {
                let changeRequest = user.createProfileChangeRequest()
                if let name = name {
                    changeRequest.displayName = name
                }
                if
                    let photoURLString = photoURLString,
                    let photoURL = URL(string: photoURLString) {
                    changeRequest.photoURL = photoURL
                }
                changeRequest.commitChanges { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(true))
                    }
                }
            } else {
                promise(.failure(AuthError.userNotExists))
            }
        }
        .eraseToAnyPublisher()
    }
}
