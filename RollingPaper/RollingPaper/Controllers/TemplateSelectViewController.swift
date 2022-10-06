//
//  TemplateSelectViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/05.
//

import UIKit
import SnapKit

class TemplateSelectViewController: UIViewController {
    private let viewModel = TemplateSelectViewModel()
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        makeRecentTemplateView()
        makeTemplatesView()
    }
    
    func makeRecentTemplateView() {
        if let recentTemplate = viewModel.getRecentTemplate() {
            let title = getMainTitle(text: "최근 사용한")
            let recentTemplateThumbnail = getThumbnail(templateEnum: recentTemplate)
            
            view.addSubview(title)
            view.addSubview(recentTemplateThumbnail)
            
            title.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(50)
                make.left.equalToSuperview().offset(48)
            }
            
            recentTemplateThumbnail.snp.makeConstraints { make in
                make.top.equalTo(title.snp.bottom).offset(27)
                make.left.equalTo(title)
            }
        }
    }
    
    func makeTemplatesView() {
        
    }
    
    func getMainTitle(text: String) -> UILabel {
        let title = UILabel()
        title.text = text
        title.font = .systemFont(ofSize: 32)
        
        return title
    }
    
    func getThumbnail(templateEnum: TemplateEnum) -> UIView {
        let thumbnail = UIView()
        let title = UILabel()
        let imageView = UIImageView(image: templateEnum.template.thumbnail)
        
        thumbnail.addSubview(imageView)
        thumbnail.addSubview(title)
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalTo(240)
        }
        
        title.text = templateEnum.template.templateString
        title.font = .systemFont(ofSize: 20)
        title.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.centerX.equalTo(imageView)
        }
        
        return thumbnail
    }
}
