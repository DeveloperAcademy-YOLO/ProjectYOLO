//
//  PaperTimePicker.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/10.
//

import UIKit
import Combine

// 제한시간 설정할 때 쓰는 피커
class PaperTimePicker: UIViewController {
    private let hourList = ["1", "2", "3", "4", "5", "6"]
    private let minuteList = ["00", "10", "20", "30", "40", "50"]
    private let hourLabel = "시간"
    private let minuteLabel = "분"
    private var selectedHour = "1"
    private var selectedMinute = "00"
    private let picker = UIPickerView()
    private let viewModel: PaperSettingViewModel
    private let input: PassthroughSubject<PaperSettingViewModel.Input, Never> = .init()
    
    init(viewModel: PaperSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setView()
        setPicker()
        compressView()
        bind()
    }
    
    // 뷰모델과 연결하기
    private func bind() {
        _ = viewModel.transform(input: input.eraseToAnyPublisher())
    }
    
    // 피커 설정하기
    private func setPicker() {
        picker.delegate = self
        picker.dataSource = self
        setPickerLabelsWith(labels: [hourLabel, minuteLabel], lengths: [hourList[0].count, minuteList[0].count])
        
        picker.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }
    // 메인 뷰 설정하기
    private func setView() {
        view.addSubview(picker)
        view.snp.makeConstraints { make in
            make.width.equalTo(250)
        }
    }
    // 뷰 크기 압축하기
    private func compressView() {
        preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
    // 라벨 달기
    func setPickerLabelsWith(labels: [String], lengths: [Int]) {
        let columCount = labels.count
        let fontSize: CGFloat = 20

        var labelList: [UILabel] = []
        for index in 0..<columCount {
            let label = UILabel()
            label.text = labels[index]
            label.font = .systemFont(ofSize: fontSize)
            label.textColor = .black
            label.sizeToFit()
            labelList.append(label)
        }

        let pickerWidth: CGFloat = picker.frame.width
        let labelY: CGFloat = (picker.frame.size.height / 2) - 3

        for (index, label) in labelList.enumerated() {
            let labelX: CGFloat = (pickerWidth / (CGFloat(columCount)*2))
                                    * CGFloat(index + 1)
                                    + fontSize*CGFloat(lengths[index])
                                    - fontSize*0.5*CGFloat(lengths[index]-1)
            label.frame = CGRect(x: labelX, y: labelY, width: fontSize*CGFloat(labels[index].count), height: fontSize)
            picker.addSubview(label)
        }
    }
}

extension PaperTimePicker: UIPickerViewDelegate, UIPickerViewDataSource {
    // 컴포넌트(목록) 개수
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    // 컴포넌트 별 아이템 개수
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? hourList.count : minuteList.count
    }
    // 보여주는 아이템
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return component == 0 ? hourList[row] : minuteList[row]
    }
    // 선택된 아이템
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedHour = hourList[row]
        } else {
            selectedMinute = minuteList[row]
        }
        input.send(.timePickerChange(time: selectedHour+hourLabel+" "+selectedMinute+minuteLabel))
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return CGFloat(80.0)
    }
}
