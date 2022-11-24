//
//  GiftPaperViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/11/15.
//

import UIKit

class GiftPaperViewController: UIViewController {

    lazy var leftButton: UIBarButtonItem = {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(named: "customBlack") ?? UIColor(red: 100, green: 100, blue: 100), renderingMode: .alwaysOriginal)
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("선물 상자", for: .normal)
        customBackBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        customBackBtn.setTitleColor(.black, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addLeftPadding(5)
        customBackBtn.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
        let button = UIBarButtonItem(customView: customBackBtn)
        return button
    }()
    
    lazy private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 36)
        titleLabel.textAlignment = .center
   //     titleLabel.text = viewModel.currentPaperPublisher.value?.title
        titleLabel.text = "선물 받은 페이퍼"
        titleLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.title3, weight: UIFont.Weight.bold)
        titleLabel.numberOfLines = 1
        
        return titleLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = titleLabel
        view.backgroundColor = .blue
        // Do any additional setup after loading the view.
    }
    
    @objc func cancelBtnPressed(_ gesture: UITapGestureRecognizer) {
        print("cancelBtnPressed")
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setCustomNavBarButtons() {
        navigationItem.leftBarButtonItem = leftButton
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemGray6
        navBarAppearance.shadowImage = UIImage.hideNavBarLine(color: UIColor.clear)
        
        self.navigationItem.standardAppearance = navBarAppearance
        self.navigationItem.scrollEdgeAppearance = navBarAppearance
    }

}
