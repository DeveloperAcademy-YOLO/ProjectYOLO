//
//  TimerDiscriptionBalloon.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/11/15.
//
import Combine
import Foundation
import SnapKit
import UIKit

class TimerDiscriptionBalloon: UIViewController {
    private lazy var balloonImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.image = UIImage(named: "TimerTapBalloon")
        
        return imageView
    }()
    
    private lazy var firstLine: BasePaddingLabel = {
        let label = BasePaddingLabel(padding: UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0))
        label.text = "타이머가 종료되면 더 이상"
        textLabelInit(label)
        
        return label
    }()
    
    private lazy var secondLine: BasePaddingLabel = {
        let label = BasePaddingLabel(padding: UIEdgeInsets(top: 3, left: 0, bottom: 17, right: 0))
        label.text = "메시지를 남길 수 없어요"
        textLabelInit(label)
        
        return label
    }()
    
    private lazy var discriptionTextStack: UIStackView = {
        let stackView = UIStackView()
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.addArrangedSubview(firstLine)
        stackView.addArrangedSubview(secondLine)
        
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(balloonImageView)
        view.addSubview(discriptionTextStack)
        balloonSizeConstraints()
        stackSizeConstraints()
    }
    
    private func textLabelInit(_ label:BasePaddingLabel){
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = true
        label.sizeToFit()
    }
}

extension TimerDiscriptionBalloon {
    private func stackSizeConstraints() {
        discriptionTextStack.snp.makeConstraints({ make in
            make.width.equalTo(224)
            make.height.equalTo(81)
        })
    }
    
    private func balloonSizeConstraints() {
        balloonImageView.snp.makeConstraints({ make in
            make.width.equalTo(224)
            make.height.equalTo(81)
        })
    }
}
