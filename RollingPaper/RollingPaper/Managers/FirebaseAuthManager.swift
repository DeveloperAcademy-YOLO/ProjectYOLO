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
    static var shared: AuthManager { get }
    var signedInSubject: PassthroughSubject<AuthManagerEnum, Never> {get set}
    var userProfileSubject: CurrentValueSubject<UserModel?, Never> { get set }
    func signIn(email: String, password: String)
    func appleSignIn()
    func signUp(email: String, password: String, name: String)
    func signOut()
    func deleteUser()
    func updateUserProfile(name: String?, photoData: Data?, contentType: DataContentType?)
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
    case emailDidMiss
    case passwordDidMiss
    case nameAlreadyInUse
    case invalidName
}

final class FirebaseAuthManager: NSObject, AuthManager {
    static let shared: AuthManager = FirebaseAuthManager()
    var signedInSubject: PassthroughSubject<AuthManagerEnum, Never> = .init()
    var userProfileSubject: CurrentValueSubject<UserModel?, Never> = .init(nil)
    private let auth = FirebaseAuth.Auth.auth()
    private var currentNonce: String?
    private var cancellables = Set<AnyCancellable>()
    
    func signUp(email: String, password: String, name: String) {
        FirestoreManager.shared.isValidUserName(with: name)
            .sink(receiveValue: { [weak self] isValid in
                guard let self = self else { return }
                if isValid {
                    print("THIS IS VALID!")
                    self.auth.createUser(withEmail: email, password: password) { [weak self] _, error in
                        guard let self = self else { return }
                        if let error = self.handleError(with: error) {
                            self.signedInSubject.send(error)
                        } else {
                            FirestoreManager.shared.setUserName(from: nil, to: name)
                                .sink(receiveValue: { [weak self] isNameSet in
                                    guard let self = self else { return }
                                    if isNameSet {
                                        self.signedInSubject.send(.signUpSucceed)
                                        self.updateUserProfile(name: name)
                                    } else {
                                        self.signedInSubject.send(.unknownError)
                                    }
                                })
                                .store(in: &self.cancellables)
                        }
                    }
                } else {
                    print("THIS IS INVALID!")
                    self.signedInSubject.send(.nameAlreadyInUse)
                }
            })
            .store(in: &cancellables)
    }
    
    private func handleError(with error: Error?) -> AuthManagerEnum? {
        var result: AuthManagerEnum?
        if let error = error {
            let authError = AuthErrorCode(_nsError: error as NSError).code
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
        fetchUserProfile()
    }
    
    func signIn(credential: AuthCredential) {
        auth.signIn(with: credential) { [weak self] _, error in
            if let error = self?.handleError(with: error) {
                self?.signedInSubject.send(error)
            } else {
                self?.signedInSubject.send(.signInSucceed)
            }
        }
        fetchUserProfile()
    }
    
    private func socialSignIn(credential: AuthCredential, name: String, photoURLString: String? = nil) {
        auth.signIn(with: credential) { [weak self] _, error in
            if let error = self?.handleError(with: error) {
                self?.signedInSubject.send(error)
            } else {
                if let user = self?.auth.currentUser {
                    self?.signedInSubject.send(.signInSucceed)
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = name
                    if let photoURLString = photoURLString {
                        changeRequest.photoURL = URL(string: photoURLString)
                    }
                    changeRequest.commitChanges(completion: { [weak self] error in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            self?.fetchUserProfile()
                            print("First Signed In and Set User Profile")
                        }
                    })
                } else {
                    self?.signedInSubject.send(.userNotFound)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            signedInSubject.send(.signOutSucceed)
        } catch {
            signedInSubject.send(.signOutFailed)
        }
        fetchUserProfile()
    }
    
    func deleteUser() {
        if let user = auth.currentUser {
            user.delete(completion: { [weak self] error in
                if error != nil {
                    self?.signedInSubject.send(.deleteUserFailed)
                } else {
                    self?.signedInSubject.send(.deleteUserSucceed)
                    self?.fetchUserProfile()
                }
            })
        }
    }
    
    func updateUserProfile(name: String?, photoData: Data?, contentType: DataContentType?) {
        if
            let user = auth.currentUser {
            let changeRequest = user.createProfileChangeRequest()
            let dataId = user.uid
            if let name = name {
                changeRequest.displayName = name
            }
            if
                let photoData = photoData,
                let contentType = contentType {
                FirebaseStorageManager.uploadData(dataId: dataId, data: photoData, contentType: contentType, pathRoot: .profile)
                    .receive(on: DispatchQueue.global(qos: .background))
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("Photo Upload Succeed")
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    }, receiveValue: { [weak self] url in
                        if let url = url {
                            changeRequest.photoURL = url
                            changeRequest.commitChanges(completion: { [weak self] error in
                                if let error = error {
                                    print(error.localizedDescription)
                                } else {
                                    self?.fetchUserProfile()
                                }
                            })
                        }
                    })
                    .store(in: &cancellables)
            }
        }
    }
    
    private func updateUserProfile(name: String? = nil, photoURLString: String? = nil) {
        if
            let user = auth.currentUser,
            var currentUser = userProfileSubject.value {
            let changeRequest = user.createProfileChangeRequest()
            if let name = name {
                changeRequest.displayName = name
                currentUser.name = name
            }
            if
                let photoURLString = photoURLString,
                let photoUrl = URL(string: photoURLString) {
                changeRequest.photoURL = photoUrl
                currentUser.profileUrl = photoURLString
            }
            
            changeRequest.commitChanges(completion: { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self?.fetchUserProfile()
                }
            })
        }
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
    
    private func fetchUserProfile() {
        if let user = auth.currentUser {
            let email = user.email ?? "Default Email"
            let name = user.displayName ?? "Default Name"
            var userProfile = UserModel(email: email, name: name)
            if let photoUrl = user.photoURL {
                userProfile.profileUrl = photoUrl.absoluteString
            }
            userProfileSubject.send(userProfile)
        } else {
            userProfileSubject.send(nil)
        }
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
        socialSignIn(credential: credential, name: name)
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
