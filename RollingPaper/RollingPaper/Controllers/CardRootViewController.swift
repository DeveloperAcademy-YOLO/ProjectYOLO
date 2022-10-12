//
//  CardRootViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/12.
//

import UIKit
import SnapKit
import Combine

class CardRootViewController: UIViewController {
    // TODO: CardRootViewModel 만들어서 ImageView에 있는 데이터 저장하고, Step1, Step2에 뿌려 준다.
    private let items = ["배경 고르기", "꾸미기"]
    
    var backgroundImg = UIImage(named: "Rectangle")
    
    private var firstStepView: UIView!
    private var secondStepView: UIView!
    
    private let viewModel = CardRootViewModel()
//    private let firstViewController = CardBackgroundViewController(viewModel: viewModel)
//    private let secondViewController = CardPencilKitViewController()
    
//    private let viewModel = CardRootViewModel()
//    private let input: PassthroughSubject<CardRootViewModel.Input, Never> = .init()
//    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        instantiateSegmentedViewControllers()
       // bind()
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        input.send(.viewDidAppear)
//        input.send(.setCardBackgroundImg(background: <#T##UIImage#>))
//    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(segmentedControl)
        segmentedControlConstraints()
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
    
//    private func bind() {
//        let output = viewModel.transform(input: input.eraseToAnyPublisher())
//        output
//            .sink { [weak self] event in
//                guard let self = self else {return}
//                switch event {
//                case .getRecentCardBackgroundImgSuccess(let background):
//                    self.backgroundImg = background
//                case .getRecentCardBackgroundImgFail:
//                    self.backgroundImg = UIImage(named: "Rectangle")
//                }
//            }
//            .store(in: &cancellables)
//    }
    
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
    
    private func segmentedControlConstraints() {
        segmentedControl.snp.makeConstraints({ make in
            make.width.equalTo(200)
            make.height.equalTo(35)
            make.centerX.equalTo(self.view)
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
