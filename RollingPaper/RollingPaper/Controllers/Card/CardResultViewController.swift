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
    
    private let viewModel: CardViewModel
    private let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: CardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        
        view.addSubview(someImageView)
        someImageView.backgroundColor = .white
        someImageView.layer.masksToBounds = true
        someImageView.layer.cornerRadius = 50
        someImageView.contentMode = .scaleAspectFill
        someImageView.image = backgroundImg
        someImageViewConstraints()
        
        view.addSubview(cancelButton)
        cancelButtonConstraints()
       // setNavigationBar()
        self.navigationController?.isNavigationBarHidden = true
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.send(.viewDidLoad)
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .getRecentCardBackgroundImgSuccess(let background):
                    DispatchQueue.main.async(execute: {
//                        self.someImageView.image = background
//                        print("background sueccess")
                    })
                case .getRecentCardBackgroundImgFail:
                    DispatchQueue.main.async(execute: {
                     // self.someImageView.image = UIImage(named: "heart.fill")
                    })
                case .getRecentCardResultImgSuccess(let result):
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = result
                        print("result Page bind sueccess")
                    })
                case .getRecentCardResultImgFail:
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "heart.fill")
                        print("result Page bind fail")
                    })
                }
            })
            .store(in: &cancellables)
    }
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.backgroundColor = .white
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        return theImageView
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("취소", for: UIControl.State.normal)
        button.setTitleColor(UIColor.black, for: UIControl.State.normal)
        button.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(813)
            make.height.equalTo(515)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func cancelButtonConstraints() {
        cancelButton.snp.makeConstraints({ make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.leading.equalTo(30)
            make.top.equalTo(self.view).offset(30)
        })
    }
    
    @objc func createBtnPressed() {
     print("게시하기 pressed")
    }

    @objc func cancelBtnPressed(_ sender: UISegmentedControl) {
        self.navigationController?.popViewController(animated: false)
       // self.dismiss(animated: false)
    }
}
