//
//  SignInViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import UIKit

class SignInViewController: UIViewController {
    private let viewModel = SignInViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setSignInViewUI()
    }
    
    private func setSignInViewUI() {
        view.backgroundColor = .systemBackground
    }
}
