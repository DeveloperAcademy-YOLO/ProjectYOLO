//
//  WaringView.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/08.
//

import UIKit
import SnapKit

class WaringView: UIView {
    private let image: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.image = UIImage(systemName: "exclamationmark.bubble.fill")?.withTintColor(UIColor(rgb: 0xFF3B30), renderingMode: .alwaysOriginal)
        return imageView
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setWaringViewLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setWaringViewLayout() {
        addSubviews([image, label])
        image.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.height.equalTo(21.52)
            make.width.equalTo(21.57)
        })
        label.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalTo(image.snp.trailing).offset(11.48)
        })
    }
    
    func showWarning(isShown: Bool, text: String? = nil) {
        if let text = text {
            label.text = text
        }
        if isShown {
            image.isHidden = false
            label.snp.updateConstraints({ make in
                make.leading.equalToSuperview()
            })
        } else {
            image.isHidden = true
            label.snp.updateConstraints({ make in
                make.leading.equalTo(image.snp.trailing).offset(11.48)
            })
        }
        layoutIfNeeded()
    }
}
