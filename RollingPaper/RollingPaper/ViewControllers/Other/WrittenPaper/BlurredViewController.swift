//
//  BlurredViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/11/13.
//
import Combine
import Foundation
import SnapKit
import UIKit

class BlurredViewController: UIViewController {
    var viewModel: WrittenPaperViewModel?
    private var cancellables = Set<AnyCancellable>()
    private let output: PassthroughSubject<Output, Never> = .init()
    
    var selectedCardIndex: Int = 0
    private let deviceWidth = UIScreen.main.bounds.size.width
    private let deviceHeight = UIScreen.main.bounds.size.height
    
    enum Input {
        case closeTapper
    }
    
    enum Output {
        case closeDone
    }
    
    private lazy var blurView = {
        let blurView = UIVisualEffectView()
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        return blurView
    }()
    private lazy var presentingVC = {
        let presentingVC = MagnifiedCardViewController()
        presentingVC.viewModel = self.viewModel
        presentingVC.selectedCardIndex = self.selectedCardIndex
        presentingVC.backgroundViewController = self
        presentingVC.modalPresentationStyle = .overFullScreen
        return presentingVC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(blurView)
        present(presentingVC, animated: true)
        animationIn()
        setBlurView()
    }
    
    func transform(inputfrom: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        inputfrom
            .sink { [weak self] receivedValue in
                guard let self = self else { return }
                switch receivedValue {
                case .closeTapper:
                    UIView.animate(withDuration: 0.5) {
                        self.presentingVC.dismiss(animated: false)
                        self.dismiss(animated: true)
                    }
                }
            }
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func animationIn() {
        UIView.animate(withDuration: 0.5) {
            self.blurView.effect = UIBlurEffect(style: .systemThinMaterial)
        }
    }
}

extension BlurredViewController {
    func setBlurView() {
        blurView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.equalTo(0)
            make.width.equalTo(deviceWidth)
            make.height.equalTo(deviceHeight)
        }
    }
}
