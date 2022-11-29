//
//  AppSettingViewModel.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/11/12.
//

import Foundation
import FirebaseAuth
import Combine

class AppSettingViewModel {
    private let authManager: AuthManager
    var cancellables = Set<AnyCancellable>()
    let currentUserSubject = PassthroughSubject<UserModel?, Never>()
    let currentPhotoSubject: CurrentValueSubject<UIImage?, Never> = .init(UIImage(systemName: "person.circle"))
    
    init(authManager: AuthManager = FirebaseAuthManager.shared) {
        self.authManager = authManager
        bind()
    }
    
    private func bind() {
        authManager
            .userProfileSubject
            .sink { [weak self] userProfile in
                self?.currentUserSubject.send(userProfile)
            }
            .store(in: &cancellables)
        authManager
            .userProfileImageSubject
            .sink { [weak self] image in
                if let image = image {
                    self?.currentPhotoSubject.send(image)
                } else {
                    self?.currentPhotoSubject.send(UIImage(systemName: "person.circle"))
                }
            }
            .store(in: &cancellables)
    }
    enum Section {
        case section1
        case section2
    }
    
    let sectionData1 = [
        AppSettingSectionModel(title: "색상 테마", detailView: UIView()),
        AppSettingSectionModel(title: "알림", detailView: UIView())
    ]
    
    let sectionData2 = [
        AppSettingSectionModel(title: "고객 지원", detailView: UIView()),
        AppSettingSectionModel(title: "정보", detailView: UIView())
    ]
}
