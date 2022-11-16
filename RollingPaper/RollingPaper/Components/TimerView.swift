//
//  TimerView.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/11.
//

import UIKit
import SnapKit
import Combine

private final class Length {
    static let timerHeight: CGFloat = 32
    static let timerWidth1: CGFloat = 172
    static let timerWidth2: CGFloat = 116
    static let timerWidth3: CGFloat = 78
    static let dateWidth: CGFloat = 95
    static let timerTopPadding: CGFloat = 6
    static let timerBottomPadding: CGFloat = 6
    static let timerRightPadding: CGFloat = 8
    static let timerLeftPadding: CGFloat = 8
    static let timerSpace: CGFloat = 4
    static let timerCornerRadius: CGFloat = 16 // 바꿔야함
    static let clockImageWidth: CGFloat = 20
    static let clockImageHeight: CGFloat = 20
    static let textWidth1: CGFloat = 132
    static let textWidth2: CGFloat = 76
    static let textWidth3: CGFloat = 38
    static let dateTextWidth: CGFloat = 75
}

// 타이머 UI
final class TimerView: UIStackView {
    private var endTime: Date?
    private var remainTimeState: RemainTimeState = .hour
    
    enum RemainTimeState {
        case hour, minute, second, end
    }
    
    // 시계 이미지
    private lazy var clock: UIImageView = {
        let clock = UIImageView()
        clock.image = UIImage(systemName: "timer")
        clock.tintColor = UIColor.white
        clock.contentMode = .scaleAspectFit
        return clock
    }()
    // 시간 라벨
    private lazy var time: UILabel = {
        let time = UILabel()
        time.font = .systemFont(ofSize: 16, weight: .semibold)
        time.textAlignment = .left
        time.textColor = UIColor.white
        return time
    }()
    // 날짜 라벨
    private lazy var dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.font = .systemFont(ofSize: 14, weight: .bold)
        dateLabel.textAlignment = .center
        dateLabel.textColor = UIColor(rgb: 0x808080)
        dateLabel.isHidden = true
        return dateLabel
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setMainView()
        configure()
        setConstraints()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 메인뷰 설정하기
    private func setMainView() {
        layer.cornerRadius = Length.timerCornerRadius
        distribution = .equalSpacing
        layoutMargins = UIEdgeInsets(top: Length.timerTopPadding, left: Length.timerLeftPadding, bottom: Length.timerBottomPadding, right: Length.timerRightPadding)
        isLayoutMarginsRelativeArrangement = true
        spacing = Length.timerSpace
    }
    
    
    // 초를 특정 포맷으로 바꾸기 (00시간 00분 00초)
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
    
    // date타입을 특정 포맷으로 바꾸기 (2022.2.4)
    private func changeTimeFormat2(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.M.d"
        return dateFormatter.string(from: date)
    }
    
    // 페이퍼 끝나는 시간 설정하도록 하기
    func setEndTime(time: Date) {
        endTime = time
        updateTime()
    }
    
    // 타이머 남은 시간 업데이트하기
    func updateTime() {
        guard let endTime = endTime else {return}
        let timeInterval = Int(endTime.timeIntervalSince(Date()))
        
        // 30분 기준으로 타이머 색상 변경
        if timeInterval > 60*30 {
            backgroundColor = UIColor.black.withAlphaComponent(0.32)
        } else if timeInterval > 0 {
            backgroundColor = UIColor.red
        } else {
            backgroundColor = UIColor(rgb: 0xF0F0F0)
        }
        
        // 남은 시간에 따라 레이아웃 가로 길이 조절
        if timeInterval < 0 && remainTimeState != .end {
            remainTimeState = .end
            clock.isHidden = true
            time.isHidden = true
            dateLabel.isHidden = false
            snp.updateConstraints({ make in
                make.width.equalTo(Length.dateWidth)
            })
            time.snp.updateConstraints({ make in
                make.width.equalTo(Length.dateTextWidth)
            })
        } else if timeInterval >= 0 && timeInterval < 60 && remainTimeState != .second {
            remainTimeState = .second
            snp.updateConstraints({ make in
                make.width.equalTo(Length.timerWidth3)
            })
            time.snp.updateConstraints({ make in
                make.width.equalTo(Length.textWidth3)
            })
        } else if timeInterval >= 60 && timeInterval < 3600 && remainTimeState != .minute {
            remainTimeState = .minute
            snp.updateConstraints({ make in
                make.width.equalTo(Length.timerWidth2)
            })
            time.snp.updateConstraints({ make in
                make.width.equalTo(Length.textWidth2)
            })
        } else if timeInterval >= 3600 && remainTimeState != .hour {
            remainTimeState = .hour
            snp.updateConstraints({ make in
                make.width.equalTo(Length.timerWidth1)
            })
            time.snp.updateConstraints({ make in
                make.width.equalTo(Length.textWidth1)
            })
        }
        
        if timeInterval < 0 {
            dateLabel.text = changeTimeFormat2(date: endTime)
        } else {
            time.text = changeTimeFormat(second: timeInterval)
        }
        
    }
}

// 스냅킷 설정
extension TimerView {
    private func configure() {
        addArrangedSubview(clock)
        addArrangedSubview(time)
        addArrangedSubview(dateLabel)
    }
    
    private func setConstraints() {
        snp.makeConstraints ({ make in
            make.width.equalTo(Length.timerWidth1)
            make.height.equalTo(Length.timerHeight)
        })
        clock.snp.makeConstraints({ make in
            make.width.equalTo(Length.clockImageWidth)
            make.height.equalTo(Length.clockImageHeight)
        })
        time.snp.makeConstraints({ make in
            make.width.equalTo(Length.textWidth1)
        })
    }
}
