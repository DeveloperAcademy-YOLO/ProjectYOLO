//
//  PaperTimePicker.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/10.
//

import UIKit

// 제한시간 설정할 때 쓰는 피커
class PaperTimePicker: UIViewController {
    private let timeList = ["00:30", "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00"]
    private let picker = UIPickerView()
    
    override func viewDidLoad() {
        setView()
        setPicker()
        compressView()
    }
    
    // 피커 설정하기
    private func setPicker() {
        picker.delegate = self
        picker.dataSource = self
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
}

extension PaperTimePicker: UIPickerViewDelegate, UIPickerViewDataSource {
    // 컴포넌트(목록) 개수
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    // 컴포넌트 별 아이템 개수
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timeList.count
    }
    // 보여주는 아이템
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return timeList[row]
    }
    // 선택된 아이템
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("Selected: \(timeList[row])")
    }
}
