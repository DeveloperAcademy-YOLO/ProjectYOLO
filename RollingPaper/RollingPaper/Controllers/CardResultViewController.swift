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
    
    private var backgroundImg = UIImage(named: "Rectangle")
    let image: UIImage
    private let paperID: String
    private let viewModel: CardViewModel
    private let isLocalDB: Bool
    private let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    init(resultImage: UIImage, paperID: String, viewModel: CardViewModel, isLocalDB: Bool) {
        self.image = resultImage
        self.paperID = paperID
        self.viewModel = viewModel
        self.isLocalDB = isLocalDB
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
        
        input.send(.viewDidLoad)
        bind()
    }
    
    private func bind() {
        _ = viewModel.transform(input: input.eraseToAnyPublisher())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        theImageView.backgroundColor = .systemBackground
        theImageView.layer.masksToBounds = true
        theImageView.layer.cornerRadius = 50
        theImageView.contentMode = .scaleAspectFill
        theImageView.image = image
        return theImageView
    }()
    
    lazy var navigationTitle: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "이대로 게시할까요?"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        return titleLabel
    }()
    
    lazy var leftButton: UIBarButtonItem = {
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("취소", for: .normal)
        customBackBtn.setTitleColor(.black, for: .normal)
        customBackBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        customBackBtn.addLeftPadding(5)
        customBackBtn.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
        
        let button = UIBarButtonItem(customView: customBackBtn)
        button.tag = 1
        return button
    }()
    
    lazy var rightButton: UIBarButtonItem = {
        let customCompleteBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customCompleteBtn.setTitle("게시", for: .normal)
        customCompleteBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        customCompleteBtn.setTitleColor(.black, for: .normal)
        customCompleteBtn.addTarget(self, action: #selector(createBtnPressed(_:)), for: .touchUpInside)
        
        let button = UIBarButtonItem(customView: customCompleteBtn)
        button.tag = 2
        return button
    }()
    
    private func setCustomNavBarButtons() {
        self.navigationItem.titleView = navigationTitle
        
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
            make.width.equalTo(self.view.bounds.width * 0.75)
            make.height.equalTo(self.view.bounds.width * 0.75 * 0.75)
            make.leading.equalTo(self.view.snp.leading).offset(self.view.bounds.width * 0.125)
            make.trailing.equalTo(self.view.snp.trailing).offset(-(self.view.bounds.width * 0.125))
            make.top.equalTo(self.view.snp.top).offset(120)
            make.bottom.equalTo(self.view.snp.bottom).offset(-90)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    @objc func cancelBtnPressed(_ sender: UISegmentedControl) {
        self.navigationController?.popViewController(animated: false)
    }
    
    @objc func createBtnPressed(_ sender: UISegmentedControl) {
        print("게시하기 pressed")
        print(isLocalDB)
        print(paperID)
        self.input.send(.resultSend(paperID: paperID, isLocalDB: isLocalDB))
     
        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
        self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3 ], animated: true)
    }
    
}
