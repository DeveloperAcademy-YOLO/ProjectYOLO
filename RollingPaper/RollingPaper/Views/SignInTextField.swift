//
//  SignInTextField.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/08.
//

import UIKit
import SnapKit

class SignInTextField: UIView {
    enum SignInTextFieldEnum {
        case email
        case password
        case name
    }
    
    enum SignInTextFieldState {
        case normal
        case focused
        case waring
        case passed
    }
    
    private var textFieldEnum: SignInTextFieldEnum?
    
    private let checkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.image = UIImage(systemName: "checkmark.circle")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
        return imageView
    }()
    
    private let nameCountView: UILabel = {
        let label = UILabel()
        label.text = "0/8"
        label.textColor = .white
        label.backgroundColor = .systemGray
        label.layer.cornerRadius = 9
        label.layer.masksToBounds = true
        return label
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 12
        textField.layer.borderColor = UIColor.systemGray.cgColor
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setTextfieldUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setTextFieldUI() {
        addSubview(textField)
        addSubview(checkImageView)
        addSubview(nameCountView)
        textField.frame = self.bounds
    }
    
    func setTextFieldType(type: SignInTextFieldEnum) {
        self.textFieldEnum = type
        switch type {
        case .email: break
        case .password: break
        case .name: break
        }
    }
    
    func setTextFieldState(state: SignInTextFieldState) {
        guard let currentTextField = textFieldEnum else { return }
        switch currentTextField {
        case .email, .password:
            switch state {
            case .normal: break
            case .focused: break
            case .waring: break
            case .passed: break
            }
        case .name:
            switch state {
            case .normal: break
            case .focused: break
            case .waring: break
            case .passed: break
            }
        }
    }
}
