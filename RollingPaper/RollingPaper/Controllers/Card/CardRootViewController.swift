//
//  CardRootViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/12.
//

import UIKit
import SnapKit
import Combine

//protocol CardRootViewControllerDelegate: AnyObject {
//    func testfunc()
//}

class CardRootViewController: UIViewController {
    
//    weak var delegate: CardRootViewControllerDelegate?
//    
//    
    private let items = ["배경 고르기", "꾸미기"]
    
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
    
    var backgroundImg = UIImage(named: "Rectangle")
    
    private var firstStepView: UIView!
    private var secondStepView: UIView!
    private var thirdStepView: UIView!
    
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
        setupViews()
        instantiateSegmentedViewControllers()
        self.navigationController?.isNavigationBarHidden = true
        input.send(.resultShown)
        bind()
    }
    
    private func setupViews() {
        view.backgroundColor = .white
     
        view.addSubview(segmentedControl)
        segmentedControlConstraints()
        
        view.addSubview(completeButton)
        completeButtonConstraints()
    }
    
    lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.layer.cornerRadius = 9
        control.layer.masksToBounds = true
        control.selectedSegmentTintColor = .darkGray
        control.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(segmentedControlViewChanged(_:)), for: .valueChanged)
        return control
    }()
    
    lazy var completeButton: UIButton = {
        let button = UIButton()
        button.setTitle("완료", for: UIControl.State.normal)
        button.setTitleColor(UIColor.black, for: UIControl.State.normal)
        button.addTarget(self, action: #selector(openResultView(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func segmentedControlViewChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            firstStepView.alpha = 1
            secondStepView.alpha = 0
        case 1:
            firstStepView.alpha = 0
            secondStepView.alpha = 1
        default:
            firstStepView.alpha = 1
            secondStepView.alpha = 0
        }
    }
    

    @objc func openResultView(_ gesture: UITapGestureRecognizer) {
        if let secondStepViewVC = self.children[0] as? CardPencilKitViewController {
            secondStepViewVC.testfunc()
            print("CardPencilKit here!")
            
        } else {
            print("Fail!")
        }
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            let pushVC = CardResultViewController(resultImage: self.backgroundImg ?? UIImage(named: "thumbnail_halloween")!)
         
            self.navigationController?.pushViewController(pushVC, animated: false)
        }) // TODO: 리팩토링 필요
    }
    
    @objc func cancelBtnPressed() {
        print("cancelBtnPressed")
    }
    
    private func segmentedControlConstraints() {
        segmentedControl.snp.makeConstraints({ make in
            make.width.equalTo(200)
            make.height.equalTo(35)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view).offset(30)
        })
    }
    
    private func completeButtonConstraints() {
        completeButton.snp.makeConstraints({ make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.trailing.equalTo(-30)
            make.top.equalTo(self.view).offset(30)
        })
    }
    
    private func instantiateSegmentedViewControllers() {
        let firstStepViewVC = CardBackgroundViewController(viewModel: viewModel)
        let secondStepViewVC = CardPencilKitViewController(viewModel: viewModel)
        
        self.addChild(secondStepViewVC)
        self.addChild(firstStepViewVC)
  
        firstStepViewVC.view.translatesAutoresizingMaskIntoConstraints = false
        secondStepViewVC.view.translatesAutoresizingMaskIntoConstraints = false
       
        self.view.addSubview(secondStepViewVC.view)
        self.view.addSubview(firstStepViewVC.view)
       
            NSLayoutConstraint.activate([
                firstStepViewVC.view.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: 10),
                firstStepViewVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                firstStepViewVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                firstStepViewVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                
                secondStepViewVC.view.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: 10),
                secondStepViewVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                secondStepViewVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                secondStepViewVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
               
            ])
            
            self.firstStepView = firstStepViewVC.view
            self.secondStepView = secondStepViewVC.view
          
        }
}
