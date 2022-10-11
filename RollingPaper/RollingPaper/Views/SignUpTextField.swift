//
//  SignInTextField.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/08.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa

class SignUpTextField: UIView {
    enum SignUpTextFieldEnum {
        case email
        case password
        case name
    }
    
    enum SignInTextFieldState {
        case normal
        case focused
        case waring(error: AuthManagerEnum)
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
        label.font = UIFont.preferredFont(for: .body, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = UIColor(red: 0.851, green: 0.851, blue: 0.851, alpha: 1)
        label.layer.cornerRadius = 9
        label.layer.masksToBounds = true
        return label
    }()
    
    let textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.backgroundColor = .white
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 12
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.layer.borderWidth = 1.0
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.layer.shadowColor = UIColor.systemGray.cgColor
        textField.layer.shadowOpacity = 0.0
        textField.layer.shadowOffset = .zero
        return textField
    }()
    
    private let waringImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.image = UIImage(systemName: "exclamationmark.bubble.fill")?.withTintColor(UIColor(rgb: 0xFF3B30), renderingMode: .alwaysOriginal)
        return imageView
    }()
    
    private let waringLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        return label
    }()
    private var cancellabels = Set<AnyCancellable>()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setDefaultLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setDefaultLayout() {
        addSubviews([textField, waringImage, waringLabel])
        textField.snp.makeConstraints({ make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(38)
        })
        waringImage.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(56)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(21.52)
            make.width.equalTo(20.26)
            make.bottom.equalToSuperview()
        })
        waringLabel.snp.makeConstraints({ make in
            make.top.equalTo(waringImage.snp.top)
            make.leading.equalToSuperview().offset(49.05)
            make.bottom.equalTo(waringImage.snp.bottom)
        })
        waringLabel.backgroundColor = .orange
    }
    
    private func setWaringView(waringShown: Bool, text: String?) {
        waringImage.isHidden = !waringShown
        waringLabel.text = text
        waringLabel.snp.updateConstraints({ make in
            make.leading.equalToSuperview().offset(waringShown ? 49.05 : 16)
        })
        layoutIfNeeded()
    }
    
    func setTextFieldType(type: SignUpTextFieldEnum) {
        self.textFieldEnum = type
        addSubview(checkImageView)
        checkImageView.snp.makeConstraints({ make in
            make.top.equalTo(snp.top).offset(9)
            make.width.height.equalTo(19.92)
            make.trailing.equalTo(snp.trailing).offset(-9.08)
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
                make.trailing.equalTo(textField.snp.trailing).offset(-5)
                make.width.equalTo(44)
                make.height.equalTo(28)
            })
            textField
                .textPublisher
                .compactMap({ $0 })
                .sink(receiveValue: { [weak self] text in
                    self?.nameCountView.text = "\(text.count)/8"
                    self?.nameCountView.backgroundColor = text.count <= 8 ? .systemGray : .systemRed
                })
                .store(in: &cancellabels)
        }
        textField
            .didBeginEditingPublisher
            .sink { [weak self] _ in
                self?.setTextFieldState(state: .focused)
            }
            .store(in: &cancellabels)
        textField.controlPublisher(for: .editingDidEnd)
            .sink { [weak self] _ in
                if
                    let currentTextField = self?.textFieldEnum,
                    let currentState = self?.handleTextfieldText(currentTextField: currentTextField, text: self?.textField.text ?? "") {
                    self?.setTextFieldState(state: currentState)
                }
            }
            .store(in: &cancellabels)
        textField.controlPublisher(for: .editingDidEndOnExit)
            .sink { [weak self] _ in
                if
                    let currentTextField = self?.textFieldEnum,
                    let currentState = self?.handleTextfieldText(currentTextField: currentTextField, text: self?.textField.text ?? "") {
                    self?.setTextFieldState(state: currentState)
                }
            }
            .store(in: &cancellabels)
    }
    
    private func isValidEmail(text: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: text)
    }
    
    private func handleTextfieldText(currentTextField: SignUpTextFieldEnum, text: String) -> SignInTextFieldState {
        let state: SignInTextFieldState
        switch currentTextField {
        case .email:
            if text.isEmpty {
                state = .waring(error: .emailDidMiss)
            } else {
                state = isValidEmail(text: text) ? .passed : .waring(error: .invalidEmail)
            }
        case .password:
            state = text.count < 6 ? .waring(error: .wrongPassword) : .passed
        case .name:
            state = text.count <= 8 ? .passed : .waring(error: .invalidName)
        }
        return state
    }
    
    func setTextFieldState(state: SignInTextFieldState) {
        guard let currentTextField = textFieldEnum else { return }
        switch currentTextField {
        case .email:
            switch state {
            case .normal:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                checkImageView.isHidden = true
                setWaringView(waringShown: false, text: nil)
            case .focused:
                textField.layer.borderColor = UIColor.systemBlue.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                checkImageView.isHidden = true
                setWaringView(waringShown: false, text: nil)
            case .waring(error: let error):
                textField.layer.borderColor = UIColor.systemRed.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                checkImageView.isHidden = true
                let text: String
                switch error {
                case .emailAlreadyInUse:
                    text = "이미 사용 중인 이메일입니다"
                case .invalidEmail:
                    text = "유효하지 않은 이메일입니다"
                case .emailDidMiss:
                    text = "이메일을 입력해주세요"
                default:
                    text = "이메일을 다시 입력해주세요"
                }
                setWaringView(waringShown: true, text: text)
            case .passed:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                checkImageView.isHidden = false
                setWaringView(waringShown: false, text: nil)
            }
        case .password:
            switch state {
            case .normal:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                checkImageView.isHidden = true
                setWaringView(waringShown: false, text: "비밀번호는 6자리 이상이어야 합니다f")
            case .focused:
                textField.layer.borderColor = UIColor.systemBlue.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                checkImageView.isHidden = true
                setWaringView(waringShown: false, text: nil)
            case .waring(error: let error):
                textField.layer.borderColor = UIColor.systemRed.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                checkImageView.isHidden = true
                let text: String
                switch error {
                case .passwordDidMiss:
                    text = "6자리 이상의 비밀번호를 사용해주세요"
                case .wrongPassword:
                    text = "6자리 이상의 비밀번호를 사용해주세요"
                default:
                    text = "비밀번호를 다시 입력해주세요"
                }
                setWaringView(waringShown: true, text: text)
            case .passed:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                checkImageView.isHidden = false
                setWaringView(waringShown: false, text: nil)
            }
        case .name:
            switch state {
            case .normal:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                nameCountView.isHidden = false
                checkImageView.isHidden = true
            case .focused:
                textField.layer.borderColor = UIColor.systemBlue.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                nameCountView.isHidden = false
                checkImageView.isHidden = true
            case .waring(error: let error):
                textField.layer.borderColor = UIColor.systemRed.cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.shadowOpacity = 1.0
                nameCountView.isHidden = false
                checkImageView.isHidden = true
                let text: String
                switch error {
                case .nameAlreadyInUse:
                    text = "이미 사용 중인 닉네임입니다"
                case .invalidName:
                    text = "닉네임 길이는 8자리 이하입니다"
                default:
                    text = "닉네임을 다시 입력해주세요"
                }
                setWaringView(waringShown: true, text: text)
            case .passed:
                textField.layer.borderColor = UIColor.systemGray.cgColor
                textField.layer.borderWidth = 1.0
                textField.layer.shadowOpacity = 0.0
                nameCountView.isHidden = true
                checkImageView.isHidden = false
                setWaringView(waringShown: false, text: nil)
            }
        }
    }
}