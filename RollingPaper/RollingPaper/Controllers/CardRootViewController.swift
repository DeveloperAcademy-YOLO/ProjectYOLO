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
    
    private var backgroundImg = UIImage(named: "Rectangle")
    
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
        view.backgroundColor = .systemBackground
        
        instantiateSegmentedViewControllers()
        setCustomNavBarButtons()
        
        input.send(.resultShown)
        bind()
    }
    
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
           button.tag = 1
           return button
       }()

    lazy var rightButton: UIBarButtonItem = {
        let customCompleteBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customCompleteBtn.setTitle("완료", for: .normal)
        customCompleteBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        customCompleteBtn.setTitleColor(.black, for: .normal)
        customCompleteBtn.addTarget(self, action: #selector(openResultView(_:)), for: .touchUpInside)
    
        let button = UIBarButtonItem(customView: customCompleteBtn)
        button.tag = 2
           return button
        }()
    
    private func setCustomNavBarButtons() {
        self.navigationItem.titleView = segmentedControl
        
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
       
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        
        self.navigationItem.standardAppearance = navBarAppearance
        self.navigationItem.scrollEdgeAppearance = navBarAppearance
    }
    
    lazy var segmentedControl: UISegmentedControl = {
        let items = ["Step1", "Step2"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.layer.cornerRadius = 9
        control.layer.masksToBounds = true
        control.clipsToBounds = true
       // control.layer.borderWidth = 1
       // control.layer.borderColor = CGColor(red: 100, green: 100, blue: 80, alpha: 1)
        control.selectedSegmentTintColor = UIColor(red: 1, green: 1, blue: 1)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.setImage(
            UIImage.textEmbededImage(
                image: UIImage(named: "first_step_icon")!,
                string: "배경 고르기",
                color: .white
            ),
            forSegmentAt: 0
        )
        control.setImage(
            UIImage.textEmbededImage(
                image: UIImage(named: "second_step_icon")!,
                string: "꾸미기",
                color: .white
            ),
            forSegmentAt: 1
        )
        control.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(segmentedControlViewChanged(_:)), for: .valueChanged)
        return control
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
            secondStepViewVC.resultImageSend()
            print("CardPencilKit here!")
            
        } else {
            print("Fail!")
        }
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            let pushVC = CardResultViewController(resultImage: self.backgroundImg ?? UIImage(named: "thumbnail_halloween")!)
         
            self.navigationController?.pushViewController(pushVC, animated: false)
        }) // TODO: 리팩토링 필요
    }
    
    @objc func cancelBtnPressed(_ gesture: UITapGestureRecognizer) {
        print("cancelBtnPressed")
        self.navigationController?.popViewController(animated: true)
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
                firstStepViewVC.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
                firstStepViewVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                firstStepViewVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                firstStepViewVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                
                secondStepViewVC.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
                secondStepViewVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                secondStepViewVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                secondStepViewVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
               
            ])
            self.firstStepView = firstStepViewVC.view
            self.secondStepView = secondStepViewVC.view
        }
}

extension UIImage {
    class func textEmbededImage(image: UIImage, string: String, color: UIColor, imageAlignment: Int = 0, segFont: UIFont? = nil) -> UIImage {
        let font = segFont ?? UIFont.boldSystemFont(ofSize: 16.0)
        let expectedTextSize: CGSize = (string as NSString).size(withAttributes: [NSAttributedString.Key.font: font])
        let width: CGFloat = expectedTextSize.width + image.size.width + 5.0
        let height: CGFloat = max(expectedTextSize.height, image.size.width)
        let size: CGSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        let fontTopPosition: CGFloat = (height - expectedTextSize.height) / 2.0
        let textOrigin: CGFloat = (imageAlignment == 0) ? image.size.width + 5 : 0
        let textPoint: CGPoint = CGPoint.init(x: textOrigin, y: fontTopPosition)
        string.draw(at: textPoint, withAttributes: [NSAttributedString.Key.font: font])
        let flipVertical: CGAffineTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
        context.concatenate(flipVertical)
        let alignment: CGFloat =  (imageAlignment == 0) ? 0.0 : expectedTextSize.width + 5.0
        context.draw(image.cgImage!, in: CGRect.init(x: alignment, y: ((height - image.size.height) / 2.0), width: image.size.width, height: image.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? UIImage(systemName: "heart.fill")!
    }
}
