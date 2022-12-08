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
    
    lazy var someImageShadow: UIView = {
        let aView = UIView()
        aView.layer.shadowOffset = CGSize(width: 3, height: 3)
        aView.layer.shadowOpacity = 0.2
        aView.layer.shadowRadius = 30.0
        aView.backgroundColor = .systemBackground
        aView.layer.cornerRadius = 24
        aView.layer.shadowColor = UIColor.black.cgColor
        aView.translatesAutoresizingMaskIntoConstraints = false
        return aView
    }()
    
    lazy var uiView: UIView = {
        let uiView = UIView()
        uiView.isUserInteractionEnabled = true
        uiView.layer.masksToBounds = true
        uiView.layer.cornerRadius = 24
        uiView.layer.borderWidth = 1
        uiView.layer.borderColor = UIColor(red: 128, green: 128, blue: 128).cgColor
        return uiView
    }()
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView(frame: someImageShadow.bounds)
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        theImageView.backgroundColor = .systemBackground
        theImageView.contentMode = .scaleToFill
        theImageView.image = image
        return theImageView
    }()
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "이대로 게시할까요?"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.backgroundColor = .white
        titleLabel.layer.cornerRadius = 12
        titleLabel.layer.masksToBounds = true
        return titleLabel
    }()
    
    lazy var tipView: UIView = {
        let tip = UIView()
        
        let triangle = CAShapeLayer()
        triangle.fillColor = UIColor.white.cgColor
        triangle.path = createRoundedTriangle(width: 25, height: 15, radius: 2)
        triangle.position = CGPoint(x: 0, y: 2)
        
        tip.layer.addSublayer(triangle)
        
        return tip
    }()
    
    func createRoundedTriangle(width: CGFloat, height: CGFloat, radius: CGFloat) -> CGPath {
        let point1 = CGPoint(x: -width / 2, y: -height / 2)
        let point2 = CGPoint(x: width / 2, y: -height / 2)
        let point3 = CGPoint(x: 0, y: height / 2)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: height / 2))
        path.addArc(tangent1End: point1, tangent2End: point2, radius: radius)
        path.addArc(tangent1End: point2, tangent2End: point3, radius: radius)
        path.addArc(tangent1End: point3, tangent2End: point1, radius: radius)
        path.closeSubpath()

        return path
    }
    
    lazy var backwardButton: UIButton = {
        let button = UIButton()
        let backwardBtnImage = UIImage(systemName: "arrow.uturn.backward")!.resized(to: CGSize(width: 30, height: 30)).withTintColor(UIColor(red: 173, green: 173, blue: 173))
        button.setImage(backwardBtnImage, for: .normal)
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
        
        view.addSubview(someImageShadow)
        someImageShadowConstraints()
        
        view.addSubview(uiView)
        uiViewConstraints()
        
        uiView.addSubview(someImageView)
        someImageViewConstraints()
        
        view.addSubview(titleLabel)
        titleBounceViewConstraints()
        animationBounce()
        
        view.addSubview(tipView)
        tipViewConstraints()
        animationBounceTip()
        
        view.addSubview(backwardButton)
        backwardButtonConstraints()
        
        view.addSubview(postingButton)
        postingButtonConstraints()
        
        self.navigationController?.isNavigationBarHidden = true
        input.send(.viewDidLoad)
        bind()
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink { [weak self] result in
                switch result {
                case .popToWrittenPaper:
                    print("aaa Result Card pop to wrriten paper")
                    let viewControllers: [UIViewController] = self?.navigationController!.viewControllers as [UIViewController]
                    self?.navigationController?.popToViewController(viewControllers[viewControllers.count - 3 ], animated: true)
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    private func animationBounce() {
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [.curveEaseInOut, .autoreverse, .repeat]) {
            self.titleLabel.frame = CGRect(x: self.titleLabel.frame.minX, y: self.titleLabel.frame.minY+12, width: self.titleLabel.frame.width, height: self.titleLabel.frame.height)
        }
    }
    
    private func animationBounceTip() {
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [.curveEaseInOut, .autoreverse, .repeat]) {
            self.tipView.frame = CGRect(x: self.tipView.frame.minX, y: self.tipView.frame.minY+12, width: self.tipView.frame.width, height: self.tipView.frame.height)
        }
    }
    
    @objc func cancelBtnPressed(_ sender: UISegmentedControl) {
        self.navigationController?.popViewController(animated: false)
    }
    
    @objc func createBtnPressed(_ sender: UISegmentedControl) {
        print("게시하기 pressed")
        print(isLocalDB)
        self.input.send(.resultSend(isLocalDB: isLocalDB))
    }
}

extension CardResultViewController {
    
    private func titleBounceViewConstraints() {
        titleLabel.snp.makeConstraints({ make in
            make.width.equalTo(234)
            make.height.equalTo(54)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
            make.bottom.equalTo(someImageView.snp.top).offset(-30)
        })
    }
    
    private func tipViewConstraints() {
        tipView.snp.makeConstraints({ make in
            make.centerX.equalTo(titleLabel.snp.centerX)
            make.top.equalTo(titleLabel.snp.bottom)
        })
    }
   
    private func uiViewConstraints() {
        uiView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.57)
            make.height.equalTo(self.view.bounds.height * 0.57)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func someImageShadowConstraints() {
        someImageShadow.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.57)
            make.height.equalTo(self.view.bounds.height * 0.57)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.57)
            make.height.equalTo(self.view.bounds.height * 0.57)
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
