//
//  CardResultViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/14.
//

import Combine
import SnapKit
import UIKit

final class CardResultViewController: UIViewController {
    
    private let image: UIImage
    private let viewModel: CardViewModel
    private let isLocalDB: Bool
    private let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    private var backgroundImg = UIImage(named: "Rectangle")
    private var cancellables = Set<AnyCancellable>()
    
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
    
    lazy var backwardButton: UIButton = {
        let button = UIButton()
        let backwardBtnImage = UIImage(systemName: "arrow.uturn.backward")!.resized(to: CGSize(width: 30, height: 30))
        button.setImage(backwardBtnImage, for: .normal)
        button.tintColor = UIColor(red: 173, green: 173, blue: 173)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var postingButton: UIButton = {
        let button = UIButton()
        button.setTitle("게시하기", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        button.tintColor = UIColor(red: 0, green: 0, blue: 0)
        button.backgroundColor = .black
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(createBtnPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    init(resultImage: UIImage, viewModel: CardViewModel, isLocalDB: Bool) {
        self.image = resultImage
        self.viewModel = viewModel
        self.isLocalDB = isLocalDB
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 128, green: 128, blue: 128)
        
        view.addSubview(someImageView)
        someImageViewConstraints()
        
        view.addSubview(backwardButton)
        backwardButtonConstraints()
        
        view.addSubview(postingButton)
        postingButtonConstraints()
        
        self.navigationController?.isNavigationBarHidden = true
        input.send(.viewDidLoad)
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func bind() {
        _ = viewModel.transform(input: input.eraseToAnyPublisher())
    }
    
    @objc func cancelBtnPressed(_ sender: UISegmentedControl) {
        self.navigationController?.popViewController(animated: false)
    }
    
    @objc func createBtnPressed(_ sender: UISegmentedControl) {
        print("게시하기 pressed")
        print(isLocalDB)
        self.input.send(.resultSend(isLocalDB: isLocalDB))
        
        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
        self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3 ], animated: true)
    }
    
}

extension CardResultViewController {
    private func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.55)
            make.height.equalTo(self.view.bounds.height * 0.55)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func backwardButtonConstraints() {
        backwardButton.snp.makeConstraints({ make in
            make.width.equalTo(63)
            make.height.equalTo(54)
            make.leading.equalTo(self.view.snp.leading).offset(self.view.bounds.width * 0.35)
            make.top.equalTo(someImageView.snp.bottom).offset(30)
        })
    }
    
    private func postingButtonConstraints() {
        postingButton.snp.makeConstraints({ make in
            make.width.equalTo(282)
            make.height.equalTo(54)
            make.leading.equalTo(backwardButton.snp.trailing).offset(20)
            make.top.equalTo(someImageView.snp.bottom).offset(30)
        })
    }
    
}
