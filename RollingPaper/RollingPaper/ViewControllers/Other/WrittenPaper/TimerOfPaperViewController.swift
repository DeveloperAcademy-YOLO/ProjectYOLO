//
//  TimerOfPaperViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/11/07.
//

import Foundation
import UIKit

class TimerOfPaperViewController: UIViewController {
    private var viewModel: WrittenPaperViewModel = WrittenPaperViewModel()
    private let now: Date = Date()
    private let timeLabel: UIStackView = UIStackView()
    private let timerImage = UIImageView(image: UIImage(systemName: "timer"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTime()
        view.addSubview(timeLabel)
        setLocation()
    }
    
    private func changeTimeFormat(second: Int) -> String {
        let hour = Int(second/3600)
        let minute = Int((second - (hour*3600))/60)
        var hourString = String(hour)
        var minuteString = String(minute)
        if hourString.count == 1 {
            hourString = "0" + hourString
        }
        if minuteString.count == 1 {
            minuteString = "0" + minuteString
        }
        return hourString + ":" + minuteString
    }
    
    private func setTime() {
        let timeInterval = Int(viewModel.currentPaper?.endTime.timeIntervalSince(now) ?? 3600*2-1)
        timerImage.tintColor = .white
        
        let timeText = UILabel()
        timeText.text = timeInterval > 0 ? "\(self.changeTimeFormat(second: timeInterval))" : "\(self.changeTimeFormat(second: 0))"
        timeText.font = UIFont.preferredFont(for: UIFont.TextStyle.body, weight: UIFont.Weight.bold)
        timeText.textColor = .white
        
        timeLabel.axis = NSLayoutConstraint.Axis.horizontal
        timeLabel.distribution = UIStackView.Distribution.fillProportionally
        
        timeLabel.addArrangedSubview(timerImage)
        timeLabel.addArrangedSubview(timeText)
        self.view.layer.cornerRadius = 18
        self.view.layer.backgroundColor = timeInterval > 0 ? UIColor(rgb: 0xADADAD).cgColor : UIColor(rgb: 0xFF3B30).cgColor
    }
    
    private func setLocation() {
        view.snp.makeConstraints({ make in
            make.width.equalTo(120)
            make.height.equalTo(36)
        })
        timeLabel.snp.makeConstraints({ make in
            make.width.equalTo(120)
            make.height.equalTo(36)
            make.leading.equalTo(12)
        })
        timerImage.snp.makeConstraints({ make in
            make.width.equalTo(27)
            make.height.equalTo(18)

        })
    }

}
