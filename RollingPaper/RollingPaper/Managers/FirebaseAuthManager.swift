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
import FirebaseFirestore

protocol AuthManager {
    static var shared: AuthManager { get }
    var signedInSubject: PassthroughSubject<AuthManagerEnum, Never> {get set}
    var userProfileSubject: CurrentValueSubject<UserModel?, Never> { get set }
    func signIn(email: String, password: String)
    func appleSignIn()
    func signUp(email: String, password: String, name: String)
    func signOut()
    func deleteUser()
    func setUserProfile(userModel: UserModel)
    func isValidUserName(name: String) -> AnyPublisher<Bool, Never>
    func fetchUserProfile()
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
    private let database = Firestore.firestore()
    private var currentNonce: String?
    private var cancellables = Set<AnyCancellable>()
    
    func isValidUserName(name: String) -> AnyPublisher<Bool, Never> {
        return Future { [weak self] promise in
            print("\(name) is valid name?")
            self?.database
                .collection(FireStoreConstants.usersNamePath.rawValue)
                .whereField("name", isEqualTo: name)
                .getDocuments(completion: { querySnapshot, _ in
                    if let documents = querySnapshot?.documents {
                        print("document searched")
                        promise(.success(documents.isEmpty ? true : false))
                    } else {
                        print("no document searched")
                        promise(.success(false))
                    }
                })
        }
        .eraseToAnyPublisher()
    }
    
    func fetchUserProfile() {
        guard let email = UserDefaults.standard.value(forKey: "currentUserEmail") as? String else {
            userProfileSubject.send(nil)
            return
        }
        database
            .collection(FireStoreConstants.usersNamePath.rawValue)
            .document(email)
            .getDocument { [weak self] document, _ in
                if
                    let document = document,
                    let data = document.data() {
                    var userModel = UserModel(email: email, name: "Default Name")
                    if let userName = data["name"] as? String {
                        userModel.name = userName
                    }
                    if let photoURLString = data["profileUrl"] as? String {
                        userModel.profileUrl = photoURLString
                    }
                    self?.userProfileSubject.send(userModel)
                }
            }
    }
    
    func setUserProfile(userModel: UserModel) {
        var userDict = ["name": userModel.name]
        if let profileUrl = userModel.profileUrl {
            userDict["profileUrl"] = profileUrl
        }
        database
            .collection(FireStoreConstants.usersNamePath.rawValue)
            .document(userModel.email)
            .setData(userDict, merge: true, completion: { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self?.fetchUserProfile()
                }
            })
    }
    
    func signUp(email: String, password: String, name: String) {
        isValidUserName(name: name)
            .sink { [weak self] isVaild in
                if isVaild {
                    print("Name is Valid")
                    self?.auth.createUser(withEmail: email, password: password, completion: { _, error in
                        if let error = self?.handleError(with: error) {
                            self?.signedInSubject.send(error)
                        } else {
                            let userModel = UserModel(email: email, name: name)
                            self?.setUserProfile(userModel: userModel)
                            self?.signedInSubject.send(.signUpSucceed)
                        }
                    })
                } else {
                    print("Name is Invalid")
                }
            }
            .store(in: &cancellables)
    }
                                  
    func signIn(email: String, password: String) {
        auth.signIn(withEmail: email, password: password, completion: { [weak self] _, error in
            if let error = self?.handleError(with: error) {
                self?.signedInSubject.send(error)
            } else {
                UserDefaults.standard.setValue(email, forKey: "currentUserEmail")
                self?.signedInSubject.send(.signInSucceed)
                self?.fetchUserProfile()
            }
        })
    }
    
    func signOut() {
        do {
            try auth.signOut()
            signedInSubject.send(.signOutSucceed)
            UserDefaults.standard.setValue(nil, forKey: "currentUserEmail")
            fetchUserProfile()
        } catch {
            signedInSubject.send(.signOutFailed)
        }
    }
    
    func deleteUser() {
        if let user = auth.currentUser {
            user.delete(completion: { [weak self] error in
                if error != nil {
                    self?.signedInSubject.send(.deleteUserFailed)
                } else {
                    self?.signedInSubject.send(.deleteUserSucceed)
                    UserDefaults.standard.setValue(nil, forKey: "currentUserEmail")
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
        var name = firstName + lastName
        if name.isEmpty {
            name = "Default Name"
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
        auth.signIn(with: credential) { [weak self] _, error in
            guard
                error == nil,
                let currentUser = self?.auth.currentUser else {
                if let error = self?.handleError(with: error) {
                    self?.signedInSubject.send(error)
                }
                return
            }
            if let currentUser = self?.auth.currentUser {
                if
                    (appleIDCredential.email == nil || appleIDCredential.email == ""),
                    let email = currentUser.email {
                    UserDefaults.standard.set(email, forKey: "currentUserEmail")
                    self?.fetchUserProfile()
                } else if
                    let email = appleIDCredential.email,
                    !email.isEmpty {
                    UserDefaults.standard.set(email, forKey: "currentUserEmail")
                    self?.setUserProfile(userModel: UserModel(email: email, name: name))
                }
                self?.signedInSubject.send(.signInSucceed)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Did Error -> No Input to SignedInSubject
    }
}

extension FirebaseAuthManager {
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
