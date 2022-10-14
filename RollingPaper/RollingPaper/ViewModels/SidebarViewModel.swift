//
//  SidebarViewModel.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/11.
//

import Foundation
import Combine

final class SidebarViewModel {

    private let authManager: AuthManager
    var cancellables = Set<AnyCancellable>()
    let currentUserSubject = PassthroughSubject<UserModel?, Never>()
    
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
    }
}
