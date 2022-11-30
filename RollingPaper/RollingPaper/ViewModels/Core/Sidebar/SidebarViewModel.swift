//
//  SidebarViewModel.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/11.
//

import Foundation
import Combine
import UIKit

final class SidebarViewModel {
    enum SidebarSection: String {
        case main
    }
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
                print("Im sending data!")
                print("Im nil ?: \(userProfile == nil)")
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
}
