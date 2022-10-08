//
//  SignInTextField.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/08.
//

import UIKit
import SnapKit
import Combine

class SignUpTextField: UIView {
    enum SignUpTextFieldEnum {
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
    
    private var textFieldEnum: SignUpTextFieldEnum?
    
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
    
    let textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 12
        textField.layer.borderColor = UIColor.systemGray.cgColor
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.layer.shadowColor = UIColor.systemGray.cgColor
        textField.layer.shadowOpacity = 0.0
        textField.layer.shadowOffset = .zero
        return textField
    }()
    
    private var cancellabels = Set<AnyCancellable>()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textField)
        textField.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTextFieldType(type: SignUpTextFieldEnum) {
        self.textFieldEnum = type
        addSubview(checkImageView)
        checkImageView.snp.makeConstraints({ make in
            make.top.equalTo(snp.top).offset(9)
            make.width.height.equalTo(19.92)
            make.trailing.equalTo(snp.trailing).offset(9.08)
        })
        checkImageView.isHidden = true
        switch type {
        case .email:
            textField.attributedPlaceholder = NSAttributedString(string: "이메일 주소", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        case .password:
            textField.attributedPlaceholder = NSAttributedString(string: "비밀번호", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
            textField.isSecureTextEntry = true
        case .name:
            textField.attributedPlaceholder = NSAttributedString(string: "닉네임", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
            addSubview(nameCountView)
            nameCountView.snp.makeConstraints({ make in
                make.top.equalToSuperview().offset(5)
                make.trailing.equalToSuperview().offset(5)
                make.width.equalTo(44)
                make.bottom.equalToSuperview().offset(5)
            })
            textField
                .textPublisher
                .compactMap({ $0 })
                .sink(receiveValue: { [weak self] text in
                    self?.nameCountView.text = "\(text.count)/8"
                })
                .store(in: &cancellabels)
        }
    }
    
    func setTextFieldState(state: SignInTextFieldState) {
        guard let currentTextField = textFieldEnum else { return }
        switch currentTextField {
        case .email, .password:
            switch state {
            case .normal:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                checkImageView.isHidden = true
            case .focused:
                textField.layer.borderColor = UIColor.systemBlue.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                checkImageView.isHidden = true
            case .waring:
                textField.layer.borderColor = UIColor.systemRed.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                checkImageView.isHidden = true
            case .passed:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                checkImageView.isHidden = false
            }
        case .name:
            switch state {
            case .normal:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                checkImageView.isHidden = true
                nameCountView.isHidden = false
            case .focused:
                textField.layer.borderColor = UIColor.systemBlue.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                checkImageView.isHidden = true
                nameCountView.isHidden = false
            case .waring:
                textField.layer.borderColor = UIColor.systemRed.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                checkImageView.isHidden = true
                nameCountView.isHidden = false
            case .passed:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                checkImageView.isHidden = false
                nameCountView.isHidden = true
            }
        }
    }
}
