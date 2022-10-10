//
//  SetRoomViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/07.
//

import UIKit
import SnapKit
import Combine

class SetPaperViewController: UIViewController {
    private let viewModel = SetPaperViewModel()
    private let input: PassthroughSubject<SetPaperViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var paper: PaperModel?
    
    // 이전 뷰에서 골랐던 템플릿 설정해주기
    init(template: String) {
        super.init(nibName: nil, bundle: nil)
        viewModel.template = template
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMainView()
        bind()
    }
    
    // Input이 설정될때마다 자동으로 transform 함수가 실행되고 그 결과값으로 Output이 오면 어떤 행동을 할지 정하기
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .createPaperSuccess(let paper):
                    self.paper = paper
                case .createPaperFail:
                    self.paper = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .white
        
        let title1 = getTitle(text: "롤링페이퍼 제목")
        let subtitle1 = getSubTitle(text: "누가 이 롤링페이퍼를 받게 되는지, 왜 받는지를 포함해서 적어주세요")
        let textField = getTextField(placeHolder: "재현이의 중학교 졸업을 축하하며")
        let title2 = getTitle(text: "타이머 설정")
        let subtitle2 = getSubTitle(text: "타이머가 종료되면 더이상 롤링페이퍼 내용을 작성하거나 편집할 수 없게 됩니다")
        
        view.addSubview(title1)
        view.addSubview(subtitle1)
        view.addSubview(textField)
        view.addSubview(title2)
        view.addSubview(subtitle2)
        
        title1.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(76)
            make.left.equalToSuperview().offset(76)
        }
        subtitle1.snp.makeConstraints { make in
            make.top.equalTo(title1.snp.bottom).offset(15)
            make.left.equalTo(title1)
        }
        textField.snp.makeConstraints { make in
            make.top.equalTo(subtitle1.snp.bottom).offset(30)
            make.left.equalTo(subtitle1)
            make.right.equalToSuperview().offset(-76)
            make.height.equalTo(40)
        }
        title2.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(60)
            make.left.equalTo(textField)
        }
        subtitle2.snp.makeConstraints { make in
            make.top.equalTo(title2.snp.bottom).offset(15)
            make.left.equalTo(title2)
        }
    }
    
    // 제목 뷰 가져오기
    private func getTitle(text: String) -> UILabel {
        let title = UILabel()
        title.text = text
        title.font = .preferredFont(forTextStyle: .title1)
        return title
    }
    
    // 부제목 뷰 가져오기
    private func getSubTitle(text: String) -> UILabel {
        let title = UILabel()
        title.text = text
        title.font = .preferredFont(forTextStyle: .title3)
        return title
    }
    
    // 텍스트필드 뷰 가져오기
    private func getTextField(placeHolder: String) -> UITextField {
        let textField = UITextField()
        let border = UIView()
        
        textField.addSubview(border)
        textField.placeholder = placeHolder
        
        textField
            .controlPublisher(for: .editingDidEndOnExit)
            .sink { _ in
                self.input.send(.setPaperTitle(title: textField.text ?? ""))
            }
            .store(in: &cancellables)
    
        border.backgroundColor = .black
        border.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
        
        return textField
    }
    
    // TODO: 네이게이션 바에 있는 생성하기 버튼을 눌렀을 때 input 값 설정 및 뷰 이동하기
}
