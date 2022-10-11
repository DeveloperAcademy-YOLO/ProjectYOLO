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
    private var isWaringShown: Bool = true
    private var textFieldBottomConstraint: ConstraintMakerEditable?
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
            textFieldBottomConstraint = make.bottom.equalToSuperview()
        })
        textFieldBottomConstraint?.constraint.deactivate()
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
    
    private func showWarning(isShown: Bool, text: String? = nil) {
        if let text = text {
            waringLabel.text = text
        }
        if isShown {
            waringLabel.snp.updateConstraints({ make in
                make.leading.equalToSuperview().offset(49.05)
            })
            waringImage.isHidden = false
        } else {
            waringLabel.snp.updateConstraints({ make in
                make.leading.equalToSuperview().offset(16)
            })
            waringImage.isHidden = true
        }
        layoutIfNeeded()
    }
    
    private func resetWaring(isShown: Bool, waringShown: Bool = false, text: String? = nil) {
        // waringImage & waringView Hidden and reset its bottom view constraint
        if isShown {
            if isWaringShown {
                waringImage.isHidden = false
                waringLabel.isHidden = false
                showWarning(isShown: true, text: text)
            } else {
                addSubviews([waringImage, waringLabel])
                textFieldBottomConstraint?.constraint.deactivate()
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
                })
            }
        } else {
            if isWaringShown {
                waringImage.snp.removeConstraints()
                waringLabel.snp.removeConstraints()
                waringImage.removeFromSuperview()
                waringLabel.removeFromSuperview()
                textFieldBottomConstraint?.constraint.activate()
            }
        }
        isWaringShown = isShown
        layoutIfNeeded()
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
            resetWaring(isShown: false)
        case .password:
            textField.attributedPlaceholder = NSAttributedString(string: "비밀번호", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
            textField.isSecureTextEntry = true
            showWarning(isShown: false, text: "비밀번호는 6자 이상이어야 합니다")
        case .name:
            textField.attributedPlaceholder = NSAttributedString(string: "닉네임", attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
            showWarning(isShown: false, text: "닉네임은 가입 이후에도 수정이 가능합니다")
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
