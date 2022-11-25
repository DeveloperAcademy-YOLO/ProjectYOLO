//
//  WarningLabel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/24.
//

import Foundation
import UIKit

final class WarningLabel: UIStackView {
    
    private var text = ""
    
    // 경고 라벨 옆에 있는 이미지
    private lazy var warningImage: UIImageView = {
        let warningImage = UIImageView()
        warningImage.contentMode = .center
        warningImage.image = UIImage(systemName: "exclamationmark.bubble.fill")?.withTintColor(UIColor(rgb: 0xFF3B30), renderingMode: .alwaysOriginal)
        return warningImage
    }()
    
    // 조건에 따라 보여주는 경고 문구
    private lazy var warningText: UILabel = {
        let warningText = UILabel()
        warningText.textColor = .systemGray
        warningText.font = .preferredFont(forTextStyle: .body)
        warningText.text = text
        return warningText
    }()
    
    convenience init(text: String) {
        self.init()
        self.text = text
        setMainView()
        configure()
    }
    
    private func setMainView() {
        spacing = 10
        axis = .horizontal
        isHidden = true
    }
    
    private func configure() {
        addArrangedSubview(warningImage)
        addArrangedSubview(warningText)
    }
    
    func showView(_ isShow: Bool) {
        isHidden = !isShow
    }
    
    func setText(text: String) {
        warningText.text = text
    }
}
