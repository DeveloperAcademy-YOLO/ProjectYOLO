//
//  SettingScreenViewModel.swift
//  RollingPaper
//
//  Created by 임 용관 on 2022/10/19.
//

import Foundation
import FirebaseAuth
import Combine

class SettingScreenViewModel {
    enum Input {
        case signOutDidTap
        case resignDidTap
        case userImageSet(image: UIImage)
        case userNameSet(name: String)
        case userProfileSet(name: String, image: UIImage)
        case userProfileNotSet
    }

    enum Output {
        case userProfileChangeDidFail
    }

    private let authManager: AuthManager
    var cancellables = Set<AnyCancellable>()
    private let output: PassthroughSubject<Output, Never> = .init()
    let currentUserSubject: CurrentValueSubject<UserModel?, Never> = .init(nil)

    init(authManager: AuthManager = FirebaseAuthManager.shared) {
        self.authManager = authManager
        bind()
    }

    private func bind() {
        authManager
            .userProfileSubject
            .sink { userModel in
                self.currentUserSubject.send(userModel)
            }
            .store(in: &cancellables)
        self.currentUserSubject.send(authManager.userProfileSubject.value)
    }

    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input
            .sink { receivedValue in
                switch receivedValue {
                case .signOutDidTap:
                    self.authManager.signOut()
                case .resignDidTap:
                    self.authManager.deleteUser()
                case .userImageSet(image: let image):
                    if let data = image.pngData() {
                        self.authManager.updateUserPhoto(photoData: data, contentType: .png)
                    }
                case .userNameSet(name: let name):
                    if let currentUser = self.currentUserSubject.value {
                        let currentName = currentUser.name
                        if currentName != name {
                            self.authManager.updateUserName(from: currentName, to: name)
                        }
                    }
                case .userProfileSet(name: let name, image: let image):
                    break
                case .userProfileNotSet:
                    break
                }
            }
            .store(in: &cancellables)

        return output.eraseToAnyPublisher()
    }
}
