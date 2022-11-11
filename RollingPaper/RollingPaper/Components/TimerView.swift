//
//  TimerView.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/11.
//

import UIKit
import SnapKit

private class Length {
    static let timerTopPadding: CGFloat = 6
    static let timerBottomPadding: CGFloat = 6
    static let timerRightPadding: CGFloat = 8
    static let timerLeftPadding: CGFloat = 8
    static let timerSpace: CGFloat = 4
    static let timerCornerRadius: CGFloat = 16 // 바꿔야함
    static let clockImageWidth: CGFloat = 20
    static let clockImageHeight: CGFloat = 20
}

class TimerView: UIStackView {
    private var endTime: Date?
    private let clock = UIImageView()
    private let time = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 페이퍼 끝나는 시간 설정하도록 하기
    func setEndTime(time: Date) {
        endTime = time
        updateTime(now: Date())
    }
    
    // 레이아웃 세팅하기
    private func setLayout() {
        addArrangedSubview(clock)
        addArrangedSubview(time)
        
        layer.cornerRadius = Length.timerCornerRadius
        distribution = .equalSpacing
        layoutMargins = UIEdgeInsets(top: Length.timerTopPadding, left: Length.timerLeftPadding, bottom: Length.timerBottomPadding, right: Length.timerRightPadding)
        isLayoutMarginsRelativeArrangement = true
        spacing = Length.timerSpace
        
        clock.image = UIImage(systemName: "timer")
        clock.tintColor = UIColor.white
        clock.contentMode = .scaleAspectFit
        clock.snp.makeConstraints({ make in
            make.width.equalTo(Length.clockImageWidth)
            make.height.equalTo(Length.clockImageHeight)
        })
        
        time.font = .preferredFont(for: .subheadline, weight: .semibold)
        time.textAlignment = .right
        time.textColor = UIColor.white
    }
    
    // 타이머 남은 시간 업데이트하기
    private func updateTime(now: Date) {
        guard let endTime = endTime else {return}
        let timeInterval = Int(endTime.timeIntervalSince(now))
        // 30분 기준으로 타이머 색상 변경
        backgroundColor = timeInterval > 60*30 ? UIColor.black.withAlphaComponent(0.32) : UIColor.red
        time.text = changeTimeFormat(second: timeInterval)
    }
    
    // 초를 특정 포맷으로 바꾸기
    private func changeTimeFormat(second: Int) -> String {
        let hourSuffix = "시간" + " "
        let minSuffix = "분" + " "
        let secSuffix = "초"
        
        let hour = Int(second/3600)
        let min = Int((second - (hour*3600))/60)
        let sec = second - (hour*3600+min*60)

        var hourString = String(hour)+hourSuffix
        var minString = String(min)+minSuffix
        var secString = String(sec)+secSuffix
        
        if hourString.count == 1+hourSuffix.count { hourString = "0" + hourString }
        if minString.count == 1+minSuffix.count { minString = "0" + minString }
        if secString.count == 1+secSuffix.count { secString = "0" + secString }
        
        if hour == 0 {
            hourString = ""
            if min == 0 {
                minString = ""
            }
        }
        
        return hourString + minString + secString
    }
}
