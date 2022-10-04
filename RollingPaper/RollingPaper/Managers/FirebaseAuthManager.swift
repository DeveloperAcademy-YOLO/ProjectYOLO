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
    var socialSignInSubject: PassthroughSubject<Bool, Never> {get set}
    func signIn(email: String, password: String) -> AnyPublisher<Bool, Error>
    func appleSignIn(window: UIWindow)
    func signUp(email: String, password: String, name: String) -> AnyPublisher<Bool, Error>
    func signOut() -> AnyPublisher<Bool, Error>
    func deleteUser() -> AnyPublisher<Bool, Error>
    func updateUserProfile(name: String?, photoURLString: String?) -> AnyPublisher<Bool, Error>
}

final class FirebaseAuthManager: NSObject, AuthManager {
    var socialSignInSubject: PassthroughSubject<Bool, Never> = .init()
    private let auth = FirebaseAuth.Auth.auth()
    private var window: UIWindow?
    private var currentNonce: String?
    
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
    
    func signIn(credential: AuthCredential) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            self?.auth.signIn(with: credential, completion: { _, error in
                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            })
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
    
    func setUserProfile(name: String? = nil, photoURLString: String? = nil) -> Void {
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
            changeRequest.commitChanges { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Setting user name and photo")
                }
            }
        }
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
    
    func appleSignIn(window: UIWindow) {
        self.window = window
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
        return window ?? UIWindow()
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
            if let error = error {
                print(error.localizedDescription)
                self.socialSignInSubject.send(false)
            } else {
                self.socialSignInSubject.send(true)
                self.setUserProfile(name: name, photoURLString: nil)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
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
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError(
              "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }
      return result
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
}
