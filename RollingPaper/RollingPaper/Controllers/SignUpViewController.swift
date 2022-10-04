//
//  SignUpViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import UIKit

class SignUpViewController: UIViewController {
    private let viewModel = SignUpViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSignUpViewUI()
    }
    
    private func setSignUpViewUI() {
        view.backgroundColor = .systemBackground
    }
}
