//
//  CardRootViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/12.
//

import Combine
import SnapKit
import UIKit

class CardRootViewController: UIViewController {
    
    private var backgroundImg: UIImage?
    private var cancellables = Set<AnyCancellable>()
    private let viewModel: CardViewModel
    private let isLocalDB: Bool
    private let currentPaper: PaperModel
    private let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    
    lazy var leftButton: UIBarButtonItem = {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(named: "customBlack") ?? UIColor(red: 100, green: 100, blue: 100), renderingMode: .alwaysOriginal)
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("돌아가기", for: .normal)
        customBackBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        customBackBtn.setTitleColor(.black, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addLeftPadding(5)
        customBackBtn.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
        
        let button = UIBarButtonItem(customView: customBackBtn)
        return button
    }()
    
    lazy var rightButton: UIBarButtonItem = {
        let customCompleteBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customCompleteBtn.setTitle("완료", for: .normal)
        customCompleteBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        customCompleteBtn.setTitleColor(.black, for: .normal)
        customCompleteBtn.addTarget(self, action: #selector(openResultView(_:)), for: .touchUpInside)
        
        let button = UIBarButtonItem(customView: customCompleteBtn)
        return button
    }()
    
    lazy var cardCreateStepView: UIView = {
        let secondStepView = UIView()
        return secondStepView
    }()
    
    init(viewModel: CardViewModel, isLocalDB: Bool, currentPaper: PaperModel) {
        self.viewModel = viewModel
        self.isLocalDB = isLocalDB
        self.currentPaper = currentPaper
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        instantiateSegmentedViewControllers()
        setCustomNavBarButtons()
        
        input.send(.resultShown)
        bind()
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .getRecentCardBackgroundImgSuccess(_):
                    DispatchQueue.main.async(execute: {
                    })
                case .getRecentCardBackgroundImgFail:
                    DispatchQueue.main.async(execute: {
                    })
                case .getRecentCardResultImgSuccess(let result):
                    DispatchQueue.main.async(execute: {
                        self.backgroundImg = result
                        print("CardrootView ResultImg import sueccess")
                    })
                case .getRecentCardResultImgFail:
                    DispatchQueue.main.async(execute: {
                        print("result Page bind fail")
                    })
                }
            })
            .store(in: &cancellables)
    }
    
    private func instantiateSegmentedViewControllers() {
        let sticker = currentPaper.template.stickerNames
        let background = currentPaper.template.backgroundImageNames
        
        let cardCreateViewVC = CardCreateViewController(viewModel: viewModel, arrStickers: sticker, backgroundImageName: background)
        
        self.addChild(cardCreateViewVC)
        cardCreateViewVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(cardCreateViewVC.view)
        self.cardCreateStepView = cardCreateViewVC.view
        cardCreateStepViewConstraints()
    }
    
    private func setCustomNavBarButtons() {
        navigationItem.title = "카드작성"
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        
        self.navigationItem.standardAppearance = navBarAppearance
        self.navigationItem.scrollEdgeAppearance = navBarAppearance
    }
    
    @objc func openResultView(_ gesture: UITapGestureRecognizer) {
        let secondStepViewVC = self.children[0] as? CardCreateViewController
        
        if secondStepViewVC?.someImageView.image == UIImage(named: "Rectangle_default") {
            let alert = UIAlertController(title: "잠깐! 카드 배경이 없어요.", message: "사진 또는 색깔을 넣어주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (_: UIAlertAction!) in
                alert.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true)
        } else {
            if let secondStepViewVC = self.children[0] as? CardCreateViewController {
                secondStepViewVC.resultImageSend()
                print("CardPencilKit here!")
            } else {
                print("Fail!")
            }
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                let pushVC = CardResultViewController(resultImage: self.backgroundImg ?? UIImage(named: "thumbnail_halloween")!, viewModel: self.viewModel, isLocalDB: self.isLocalDB)
                self.navigationController?.pushViewController(pushVC, animated: false)
            })
        }
    }
    
    @objc func cancelBtnPressed(_ gesture: UITapGestureRecognizer) {
        print("cancelBtnPressed")
        let alert = UIAlertController(title: "잠깐! 작성중인 카드가 사라져요.", message: "페이퍼로 돌아가시겠습니까?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .destructive, handler: { (_: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (_: UIAlertAction!) in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }
}

extension CardRootViewController {
    private func cardCreateStepViewConstraints() {
        cardCreateStepView.snp.makeConstraints({ make in
            make.top.equalTo(self.view).offset(30)
            make.leading.equalTo(self.view).offset(0)
            make.bottom.equalTo(self.view).offset(0)
            make.trailing.equalTo(self.view).offset(0)
        })
    }
}
