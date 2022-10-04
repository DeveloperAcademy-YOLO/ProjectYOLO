//
//  SingUpViewModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import Combine

class SignUpViewModel {
    var email = CurrentValueSubject<String, Never>("")
    var password = CurrentValueSubject<String, Never>("")
    var nickname = CurrentValueSubject<String, Never>("")
    private let authManager: AuthManager
    
    init(authManager: AuthManager = FirebaseAuthManager()) {
        self.authManager = authManager
        addSubscriber()
    }
    
    private func addSubscriber() {
        
    }
}
