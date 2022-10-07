//
//  AuthManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import FirebaseAuth
import Combine
import AuthenticationServices
import CryptoKit

protocol AuthManager {
    var signedInSubject: PassthroughSubject<AuthManagerEnum, Never> {get set}
    func signIn(email: String, password: String)
    func appleSignIn()
    func signUp(email: String, password: String, name: String) -> AnyPublisher<Bool, Error>
    func signOut()
    func deleteUser() -> AnyPublisher<Bool, Error>
    func updateUserProfile(name: String?, photoURLString: String?) -> AnyPublisher<Bool, Error>
}

enum AuthManagerEnum: String, CaseIterable {
    case userNotFound
    case userTokenExpired
    case emailAlreadyInUse
    case wrongPassword
    case invalidEmail
    case signOutFailed
    case unknownError
    case profileSetFailed
    case deleteUserFailed
    case signInSucceed
    case signUpSucceed
    case signOutSucceed
    case profileSetSucceed
    case deleteUserSucceed
}

final class FirebaseAuthManager: NSObject, AuthManager {
    var signedInSubject: PassthroughSubject<AuthManagerEnum, Never> = .init()
    private let auth = FirebaseAuth.Auth.auth()
    private var currentNonce: String?
    
    func signUp(email: String, password: String, name: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error>({ [weak self] promise in
            self?.auth.createUser(withEmail: email, password: password, completion: { _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            })
        })
        .eraseToAnyPublisher()
    }
    
    private func handleError(with error: Error?) -> AuthManagerEnum? {
        var result: AuthManagerEnum?
        if let error = error as? NSError {
            let authError = AuthErrorCode(_nsError: error).code
            switch authError {
            case .userNotFound:
                result = .userNotFound
            case .userTokenExpired:
                result = .userTokenExpired
            case .emailAlreadyInUse:
                result = .emailAlreadyInUse
            case .wrongPassword:
                result = .wrongPassword
            case .invalidEmail:
                result = .invalidEmail
            default: result = .unknownError
            }
        }
        return result
    }
                                  
    func signIn(email: String, password: String) {
        auth.signIn(withEmail: email, password: password, completion: { [weak self] _, error in
            if let error = self?.handleError(with: error) {
                self?.signedInSubject.send(error)
            } else {
                self?.signedInSubject.send(.signInSucceed)
            }
        })
    }
    
    func signIn(credential: AuthCredential) {
        auth.signIn(with: credential) { [weak self] _, error in
            if let error = self?.handleError(with: error) {
                self?.signedInSubject.send(error)
            } else {
                self?.signedInSubject.send(.signInSucceed)
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            signedInSubject.send(.signOutFailed)
        } catch {
            signedInSubject.send(.signOutSucceed)
        }
    }
    
    func deleteUser() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error>({ [weak self] promise in
            if let user = self?.auth.currentUser {
                user.delete(completion: { error in
                    if error != nil {
                        promise(.success(false))
                        self?.signedInSubject.send(.deleteUserFailed)
                    } else {
                        promise(.success(true))
                        self?.signedInSubject.send(.deleteUserFailed)
                    }
                })
            } else {
                promise(.success(false))
                self?.signedInSubject.send(.userNotFound)
            }
        })
        .eraseToAnyPublisher()
    }
    
    func setUserProfile(name: String? = nil, photoURLString: String? = nil) {
        if let user = auth.currentUser {
            let changeRequest = user.createProfileChangeRequest()
            if let name = name {
                changeRequest.displayName = name
            }
            if
                let photoURLString = photoURLString,
                let photoURL = URL(string: photoURLString) {
                changeRequest.photoURL = photoURL
            }
            changeRequest.commitChanges(completion: { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Setting user name and photo")
                }
            })
        }
    }
    
    func updateUserProfile(name: String? = nil, photoURLString: String? = nil) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error>({ [weak self] promise in
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
                changeRequest.commitChanges(completion: { error in
                    if error != nil {
                        promise(.success(false))
                    } else {
                        promise(.success(true))
                    }
                })
            } else {
                promise(.success(false))
            }
        })
        .eraseToAnyPublisher()
    }
    
    func appleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension FirebaseAuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = UIApplication.shared.currentWindow {
            return window
        } else {
            return UIWindow()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            return
        }
        
        let firstName = appleIDCredential.fullName?.givenName ?? ""
        let lastName = appleIDCredential.fullName?.familyName ?? ""
        let name = lastName + firstName

        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
        
        auth.signIn(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            if let error = self.handleError(with: error) {
                self.signedInSubject.send(error)
            } else {
                self.setUserProfile(name: name, photoURLString: nil)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signedInSubject.send(.unknownError)
    }
}

extension FirebaseAuthManager {
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map({ _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            })
            
            randoms.forEach({ random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            })
        }
        return result
    }
        
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap({
        String(format: "%02x", $0)
      }).joined()

      return hashString
    }
}
