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
        case nameAlreadyInUse
        case userProfileChangeDidSuccess
        case signOutDidSucceed
    }

    private let authManager: AuthManager
    var cancellables = Set<AnyCancellable>()
    private let output: PassthroughSubject<Output, Never> = .init()
    let currentUserSubject: CurrentValueSubject<UserModel?, Never> = .init(nil)
    let currentPhotoSubject: CurrentValueSubject<UIImage?, Never> = .init(UIImage(systemName: "person"))
    
    init(authManager: AuthManager = FirebaseAuthManager.shared) {
        self.authManager = authManager
        bind()
    }

    private func bind() {
        authManager
            .userProfileSubject
            .removeDuplicates(by: { past, current in
                if
                    past?.name == current?.name,
                    past?.profileUrl == current?.profileUrl,
                    past?.email == current?.email {
                    return true
                } else {
                    return false
                }
            })
            .sink { userModel in
                self.currentUserSubject.send(userModel)
            }
            .store(in: &cancellables)
        self.currentUserSubject.send(authManager.userProfileSubject.value)
        currentUserSubject
            .removeDuplicates(by: { past, current in
                if
                    past?.name == current?.name,
                    past?.profileUrl == current?.profileUrl,
                    past?.email == current?.email {
                    return true
                } else {
                    return false
                }
            })
            .sink { userModel in
                var photoStorage = Set<AnyCancellable>()
                if let photoURLString = userModel?.profileUrl {
                    if let image = NSCacheManager.shared.getImage(name: photoURLString) {
                        print("CacheManager Called!")
                        self.currentPhotoSubject.send(image)
                    } else {
                        print("LocalDatabaseManager Called!")
                        LocalStorageManager.downloadData(urlString: photoURLString)
                            .receive(on: DispatchQueue.global(qos: .background))
                            .sink { completion in
                                switch completion {
                                case .failure(let error):
                                    print(error.localizedDescription)
                                    FirebaseStorageManager.downloadData(urlString: photoURLString)
                                        .receive(on: DispatchQueue.global(qos: .background))
                                        .sink { completion in
                                            switch completion {
                                            case .finished: break
                                            case .failure(let error):
                                                print(error.localizedDescription)
                                                self.currentPhotoSubject.send(nil)
                                            }
                                        } receiveValue: { [weak self] data  in
                                            if
                                                let data = data,
                                                let image = UIImage(data: data) {
                                                NSCacheManager.shared.setImage(image: image, name: photoURLString)
                                                self?.currentPhotoSubject.send(image)
                                            } else {
                                                self?.currentPhotoSubject.send(nil)
                                            }
                                        }
                                        .store(in: &photoStorage)

                                case .finished: break
                                }
                            } receiveValue: { [weak self] data in
                                if
                                    let data = data,
                                    let image = UIImage(data: data) {
                                    self?.currentPhotoSubject.send(image)
                                    NSCacheManager.shared.setImage(image: image, name: photoURLString)
                                } else {
                                    FirebaseStorageManager.downloadData(urlString: photoURLString)
                                        .receive(on: DispatchQueue.global(qos: .background))
                                        .sink { [weak self] completion in
                                            switch completion {
                                            case .finished: break
                                            case .failure(let error):
                                                print(error.localizedDescription)
                                                self?.currentPhotoSubject.send(nil)
                                            }
                                        } receiveValue: { [weak self] data  in
                                            if
                                                let data = data,
                                                let image = UIImage(data: data) {
                                                NSCacheManager.shared.setImage(image: image, name: photoURLString)
                                                self?.currentPhotoSubject.send(image)
                                            } else {
                                                self?.currentPhotoSubject.send(nil)
                                            }
                                        }
                                        .store(in: &photoStorage)
                                }
                            }
                            .store(in: &photoStorage)

                    }
                }
            }
            .store(in: &cancellables)
    }

    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input
            .sink { receivedValue in
                switch receivedValue {
                case .signOutDidTap:
                    self.authManager.signOut()
                    self.output.send(.signOutDidSucceed)
                case .resignDidTap:
                    self.authManager.deleteUser()
                case .userImageSet(image: let image):
                    if
                        var currentUserModel = self.currentUserSubject.value,
                        let data = image.jpegData(compressionQuality: 0.2) {
                        FirebaseStorageManager.uploadData(dataId: self.currentUserSubject.value?.email ?? "", data: data, contentType: .jpeg, pathRoot: .profile)
                            .sink { completion in
                                switch completion {
                                case .finished: break
                                case .failure(let error):
                                    self.output.send(.userProfileChangeDidFail)
                                    print(error.localizedDescription)
                                }
                            } receiveValue: { [weak self] photoURL in
                                if let photoURLString = photoURL?.absoluteString {
                                    currentUserModel.profileUrl = photoURLString
                                    self?.authManager.setUserProfile(userModel: currentUserModel)
                                    self?.output.send(.userProfileChangeDidSuccess)
                                    print("Output Send!")
                                }
                            }
                            .store(in: &self.cancellables)
                    }
                    
                case .userNameSet(name: let name):
                    if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
                        var userModel = UserModel(email: currentUserEmail, name: name)
                        if name == self.currentUserSubject.value?.name {
                            self.output.send(.userProfileChangeDidSuccess)
                        } else {
                            self.authManager.isValidUserName(name: name)
                                .sink { isValid in
                                    print("changed name \(name) is valid and then set this name as user profile")
                                    if isValid {
                                        self.authManager.setUserProfile(userModel: userModel)
                                        self.output.send(.userProfileChangeDidSuccess)
                                    } else {
                                        self.output.send(.nameAlreadyInUse)
                                    }
                                }
                                .store(in: &self.cancellables)
                        }
                    }
                case .userProfileSet(name: let name, image: let image):
                    if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
                        if
                            let currentName = self.currentUserSubject.value?.name,
                            currentName != name {
                            self.authManager.isValidUserName(name: name)
                                .sink { isValid in
                                    if isValid {
                                        if
                                            var currentUserModel = self.currentUserSubject.value,
                                            let data = image.jpegData(compressionQuality: 0.2) {
                                            FirebaseStorageManager.uploadData(dataId: self.currentUserSubject.value?.email ?? "", data: data, contentType: .jpeg, pathRoot: .profile)
                                                .receive(on: DispatchQueue.global(qos: .background))
                                                .sink { completion in
                                                    switch completion {
                                                    case .finished: break
                                                    case .failure(let error):
                                                        self.output.send(.userProfileChangeDidFail)
                                                        print(error.localizedDescription)
                                                    }
                                                } receiveValue: { [weak self] photoURL in
                                                    if let photoURLString = photoURL?.absoluteString {
                                                        currentUserModel.name = name
                                                        currentUserModel.profileUrl = photoURLString
                                                        self?.authManager.setUserProfile(userModel: currentUserModel)
                                                        self?.output.send(.userProfileChangeDidSuccess)
                                                        NSCacheManager.shared.setImage(image: image, name: photoURLString)
                                                    } else {
                                                        self?.output.send(.userProfileChangeDidFail)
                                                    }
                                                }
                                                .store(in: &self.cancellables)
                                        }
                                    } else {
                                        self.output.send(.nameAlreadyInUse)
                                    }
                                }
                                .store(in: &self.cancellables)
                        }
                    }
                case .userProfileNotSet:
                        self.output.send(.userProfileChangeDidSuccess)
                }
            }
            .store(in: &cancellables)

        return output.eraseToAnyPublisher()
    }
}
