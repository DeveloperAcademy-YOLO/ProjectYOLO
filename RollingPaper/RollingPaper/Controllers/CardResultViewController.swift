//
//  CardResultViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/14.
//

import UIKit
import SnapKit
import Combine

final class CardResultViewController: UIViewController {
 
    var backgroundImg = UIImage(named: "Rectangle")
    let image: UIImage
    
    init(resultImage: UIImage) {
        self.image = resultImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        
        view.addSubview(someImageView)
      
        someImageViewConstraints()
        
        setCustomNavBarButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.backgroundColor = .white
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        theImageView.backgroundColor = .white
        theImageView.layer.masksToBounds = true
        theImageView.layer.cornerRadius = 50
        theImageView.contentMode = .scaleAspectFill
        theImageView.image = image
        return theImageView
    }()
    
    lazy var leftButton: UIBarButtonItem = {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(named: "customBlack") ?? UIColor(red: 100, green: 100, blue: 100), renderingMode: .alwaysOriginal)
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("취소", for: .normal)
        customBackBtn.setTitleColor(.black, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addLeftPadding(5)
        customBackBtn.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
        
        let button = UIBarButtonItem(customView: customBackBtn)
           button.tag = 1
           return button
       }()

    lazy var rightButton: UIBarButtonItem = {
        let customCompleteBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customCompleteBtn.setTitle("게시", for: .normal)
        customCompleteBtn.setTitleColor(.black, for: .normal)
        customCompleteBtn.addTarget(self, action: #selector(createBtnPressed(_:)), for: .touchUpInside)
    
        let button = UIBarButtonItem(customView: customCompleteBtn)
        button.tag = 2
           return button
        }()
    
    func setCustomNavBarButtons() {
        self.navigationItem.title = "이대로 게시할까요?"
        
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
       
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        
        self.navigationItem.standardAppearance = navBarAppearance
        self.navigationItem.scrollEdgeAppearance = navBarAppearance
    }
    
    func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(813)
            make.height.equalTo(515)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(15)
        })
    }

    @objc func cancelBtnPressed(_ sender: UISegmentedControl) {
        self.navigationController?.popViewController(animated: false)
    }
    
    @objc func createBtnPressed(_ sender: UISegmentedControl) {
     print("게시하기 pressed")
    }

}
