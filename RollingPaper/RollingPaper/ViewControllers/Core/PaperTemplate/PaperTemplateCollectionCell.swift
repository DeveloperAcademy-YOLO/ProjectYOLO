//
//  PaperTemplateCollectionCell.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/14.
//

import UIKit

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰
final class PaperTemplateCollectionCell: UICollectionViewCell {
    static let identifier = "CollectionCell"
    
    // 셀 전체를 나타내는 뷰
    private lazy var cell: UIStackView = {
        let cell = UIStackView()
        cell.spacing = PaperTemplateSelectLength.templateTitleTopMargin
        cell.axis = .vertical
        return cell
    }()
    // 템플릿 제목
    private lazy var title: UILabel = {
        let title = UILabel()
        title.font = .preferredFont(forTextStyle: .body)
        title.textColor = UIColor(rgb: 0x808080)
        title.textAlignment = .center
        return title
    }()
    // 템플릿 썸네일
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = PaperTemplateSelectLength.templateThumbnailCornerRadius
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 해당되는 셀 설정하기
    func setCell(template: TemplateModel) {
        imageView.image = template.thumbnail
        title.text = template.templateString.firstUppercased
    }
}

extension StringProtocol {
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { return prefix(1).capitalized + dropFirst() }
}
// 스냅킷 설정
extension PaperTemplateCollectionCell {
    private func configure() {
        addSubview(cell)
        cell.addArrangedSubview(imageView)
        cell.addArrangedSubview(title)
    }
    
    private func setConstraints() {
        cell.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        imageView.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(PaperTemplateSelectLength.templateThumbnailWidth)
            make.height.equalTo(PaperTemplateSelectLength.templateThumbnailHeight)
        })
        title.snp.makeConstraints({ make in
            make.centerX.equalTo(imageView)
            make.width.equalToSuperview()
        })
    }
}
