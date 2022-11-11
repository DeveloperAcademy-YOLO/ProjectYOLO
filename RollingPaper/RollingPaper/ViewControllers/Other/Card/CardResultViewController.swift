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
    private var animator: UIDynamicAnimator?
    private var collision: UICollisionBehavior!
    
    lazy var someImageShadow: UIView = {
        let aView = UIView()
        aView.layer.shadowOffset = CGSize(width: 3, height: 3)
        aView.layer.shadowOpacity = 0.2
        aView.layer.shadowRadius = 30.0
        aView.backgroundColor = .systemBackground
        aView.layer.cornerRadius = 60
        aView.layer.shadowColor = UIColor.black.cgColor
        aView.translatesAutoresizingMaskIntoConstraints = false
        return aView
    }()
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView(frame: someImageShadow.bounds)
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        theImageView.backgroundColor = .systemBackground
        theImageView.contentMode = .scaleToFill
        theImageView.layer.masksToBounds = true
        theImageView.layer.cornerRadius = 50
        
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
    
    lazy var titleBounceView: UILabel = {
        let titleLabel = UILabel(frame: CGRect(x: (view.bounds.width*0.5)-117, y: 20, width: 234, height: 54))
           titleLabel.text = "이대로 게시할까요?"
           titleLabel.textAlignment = .center
           titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
           titleLabel.backgroundColor = .white
           titleLabel.layer.cornerRadius = 12
           titleLabel.layer.masksToBounds = true
           return titleLabel
    }()

    lazy var barrierView: UIView = {
        let barrier = UIView(frame: CGRect(x: 0, y: 140, width: view.bounds.width, height: 0.1))
        barrier.backgroundColor = UIColor(red: 128, green: 128, blue: 128)
        return barrier
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
        
        view.addSubview(someImageView)
        someImageViewConstraints()
        
        view.addSubview(titleBounceView)
        view.addSubview(barrierView)
        
        titleBouncing()
        
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
    
    private func titleBouncing() {
        animator = UIDynamicAnimator(referenceView: self.view)
      
        let gravity = UIGravityBehavior(items: [titleBounceView])
        
        let vector = CGVector(dx: 0.0, dy: 0.6)
        gravity.gravityDirection = vector
        
        animator?.addBehavior(gravity)
        gravity.addItem(titleBounceView)
        
        collision = UICollisionBehavior(items: [titleBounceView])
        collision.translatesReferenceBoundsIntoBoundary = true
       
        animator?.addBehavior(collision)
        collision.addBoundary(withIdentifier: "barrier" as NSCopying, for: UIBezierPath(rect: barrierView.frame))
        let behavior = UIDynamicItemBehavior(items: [titleBounceView])
        // 탄성 설정 값이 높을수록 높게 튀어오름, 단 1.0 보다 높으면 엄청 빠르게 튀어버려서 튕겨져 나감
        behavior.elasticity = 0.975
        animator?.addBehavior(behavior)
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

extension UIView {
    func animationBounce() {
        UIView.animateKeyframes(withDuration: 0.7, delay: 0) { [weak self] in
            guard let height = self?.bounds.height else {
                return
            }
            self?.alpha = 1
            self?.center.y = -height/4
            self?.isHidden = false
        }
    }
}

extension CardResultViewController {
    private func someImageShadowConstraints() {
        someImageShadow.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.60)
            make.height.equalTo(self.view.bounds.height * 0.60)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view.snp.top).offset(150)
        })
    }
    
    private func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.60)
            make.height.equalTo(self.view.bounds.height * 0.60)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view.snp.top).offset(150)
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
