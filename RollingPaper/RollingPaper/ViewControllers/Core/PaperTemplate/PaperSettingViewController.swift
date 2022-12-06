//
//  SetRoomViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/07.
//

import Combine
import SnapKit
import UIKit

final class PaperSettingViewController: UIViewController {
    private let textLimit = 30
    private let template: TemplateEnum
    private let input: PassthroughSubject<PaperSettingViewModel.Input, Never> = .init()
    private let noTimeText = "0시간 00분"
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: PaperSettingViewModel
    private var textState: TextState = .noText
    private var timerState: TimerState = .normal
    
    // 페이퍼 제목 입력하는 텍스트필드
    private lazy var paperTitleTextField: UITextField = {
        let paperTitleTextField = UITextField()
        let placeHolder = "재현이의 중학교 졸업을 축하하며"
        paperTitleTextField.attributedPlaceholder = NSAttributedString(string: placeHolder, attributes: [.foregroundColor: UIColor.placeholderText])
        return paperTitleTextField
    }()
    // 텍스트필드 밑에 있는 선
    private lazy var textFieldBorder: UIView = {
        let textFieldBorder = UIView()
        textFieldBorder.backgroundColor = .opaqueSeparator
        return textFieldBorder
    }()
    // 텍스트필드에 입력된 글자가 몇개인지 알려주는 라벨
    private lazy var titleLengthLabel: UILabel = {
        let titleLengthLabel = UILabel()
        titleLengthLabel.text = "0/\(textLimit)"
        titleLengthLabel.font = UIFont.preferredFont(for: .body, weight: .semibold)
        titleLengthLabel.textAlignment = .center
        titleLengthLabel.textColor = .white
        titleLengthLabel.backgroundColor = .systemGray
        titleLengthLabel.layer.cornerRadius = 9
        titleLengthLabel.layer.masksToBounds = true
        return titleLengthLabel
    }()
    // 누르면 피커가 보이는 버튼
    private lazy var timePickerButton: UIButton = {
        let timePickerButton = UIButton()
        timePickerButton.addTarget(self, action: #selector(onClickedTimePickerButton(_:)), for: .touchUpInside)
        timePickerButton.setTitle(PaperSettingViewModel.defaultTime, for: .normal)
        timePickerButton.setTitleColor(.label, for: .normal)
        timePickerButton.layer.cornerRadius = PaperSettingLength.timePickerButtonRadius
        timePickerButton.backgroundColor = .systemGray5
        // timePickerButton.backgroundColor = UIColor(rgb: 0x767680).withAlphaComponent(0.12)
        return timePickerButton
    }()
    // 제한 시간 정할 수 있는 피커
    private lazy var timePicker: PaperTimePicker = {
        let timePicker = PaperTimePicker(viewModel: viewModel)
        return timePicker
    }()
    private lazy var gradientView: UIView = {
        let gradientView = UIView()
        gradientView.setGradient(
            color1: UIColor(cgColor: CGColor(gray: 0.0, alpha: 0.0)),
            color2: UIColor(cgColor: CGColor(gray: 0.0, alpha: 0.2)),
            bounds: CGRect(x: 0, y: 0, width: PaperSettingLength.thumbnailWidth, height: PaperSettingLength.thumbnailHeight)
        )
        return gradientView
    }()
    // 템플릿 썸네일 이미지
    private lazy var thumbnail: UIImageView = {
        let thumbnail = UIImageView()
        thumbnail.layer.masksToBounds = true
        thumbnail.layer.cornerRadius = PaperSettingLength.thumbnailRadius
        thumbnail.image = template.template.thumbnailDetail
        return thumbnail
    }()
    // 템플릿 제목
    private lazy var thumbnailTitle: UILabel = {
        let thumbnailTitle = UILabel()
        thumbnailTitle.text = template.template.templateTitle
        thumbnailTitle.textColor = .white
        thumbnailTitle.numberOfLines = 0
        thumbnailTitle.font = .preferredFont(for: .title2, weight: .bold)
        return thumbnailTitle
    }()
    // 템플릿 설명
    private lazy var thumbnailDescription: UILabel = {
        let thumbnailDescription = UILabel()
        thumbnailDescription.text =  template.template.templateDescription
        thumbnailDescription.textColor = .white
        thumbnailDescription.numberOfLines = 0
        thumbnailDescription.font = .preferredFont(forTextStyle: .body)
        return thumbnailDescription
    }()
    private lazy var title1: UILabel = {
        return getLabel(text: "롤링페이퍼 제목", style: .title2, color: .label)
    }()
    private lazy var subtitle1: UILabel = {
        return getLabel(text: "누가 이 롤링페이퍼를 받게 되는지, 왜 받는지를 포함해서 적어주세요", style: .body, color: .secondaryLabel)
    }()
    private lazy var title2: UILabel = {
        return getLabel(text: "타이머 설정", style: .title2, color: .label)
    }()
    private lazy var subtitle2: UILabel = {
        return getLabel(text: "타이머가 종료되면 더이상 롤링페이퍼 내용을 작성하거나 편집할 수 없게 됩니다", style: .body, color: .secondaryLabel)
    }()
    private lazy var limitTimeTitle: UILabel = {
        return getLabel(text: "제한 시간", style: .title3, color: .label)
    }()
    private lazy var warningLabelForTitle: WarningLabel = {
        return WarningLabel(text: "")
    }()
    private lazy var warningLabelForTimer: WarningLabel = {
        return WarningLabel(text: "")
    }()
    
    enum TextState {
        case normal, noText, tooLong
        var sentence: String {
            switch self {
            case .normal:
                return ""
            case .noText:
                return "페이퍼 제목을 입력해주세요!"
            case .tooLong:
                return "페이퍼 제목이 너무 길어요!"
            }
        }
    }
    
    enum TimerState {
        case normal, noTime
        var sentence: String {
            switch self {
            case .normal:
                return ""
            case .noTime:
                return "최소 10분의 시간을 설정해주세요!"
            }
        }
    }
    
    // 이전 뷰에서 골랐던 템플릿 설정해주기
    init(template: TemplateEnum) {
        self.template = template
        viewModel = PaperSettingViewModel(template: template)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setNavigationBar()
        setMainView()
        setTextFieldControl()
        configure()
        setConstraints()
    }
    
    // Input이 설정될때마다 자동으로 transform 함수가 실행되고 그 결과값으로 Output이 오면 어떤 행동을 할지 정하기
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .timePickerChange(let time):
                    self.timePickerButton.setTitle(time, for: .normal)
                    if time == self.noTimeText {
                        self.timerState = .noTime
                    } else {
                        self.timerState = .normal
                        // 타이머 경고 라벨 설정하기
                        self.setTimerWarningLabel(state: self.timerState)
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    // 네비게이션 바 초기화
    private func setNavigationBar() {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor.label ?? UIColor(red: 128, green: 128, blue: 128), renderingMode: .alwaysOriginal)
        let leftCustomBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        leftCustomBackBtn.setTitle("템플릿", for: .normal)
        leftCustomBackBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        leftCustomBackBtn.setTitleColor(.label, for: .normal)
        leftCustomBackBtn.setImage(customBackBtnImage, for: .normal)
        leftCustomBackBtn.addLeftPadding(5)
        leftCustomBackBtn.addTarget(self, action: #selector(backBtnPressed), for: .touchUpInside)
        
        let righCustomCreateBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        righCustomCreateBtn.setTitle("생성하기", for: .normal)
        righCustomCreateBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        righCustomCreateBtn.setTitleColor(.label, for: .normal)
        righCustomCreateBtn.addTarget(self, action: #selector(createBtnPressed), for: .touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftCustomBackBtn)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: righCustomCreateBtn)
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .systemBackground

        let gesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(gesture)
    }
    
    // 제목 뷰에서 공통된 컴포넌트들 설정해서 가져오기
    private func getLabel(text: String, style: UIFont.TextStyle, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = color
        label.font = .preferredFont(forTextStyle: style)
        label.numberOfLines = 0
        return label
    }
    
    // 텍스트필드 컨트롤에 관한 설정들 해주기
    private func setTextFieldControl() {
        // 제목 입력할때마다 입력한 글자 저장
        paperTitleTextField
            .controlPublisher(for: .editingChanged)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else {return}
                self.input.send(.setPaperTitle(title: self.paperTitleTextField.text ?? ""))
                let textCount = self.paperTitleTextField.text?.count ?? 0
                self.titleLengthLabel.text = "\(textCount)/\(self.textLimit)"
                self.titleLengthLabel.backgroundColor = textCount <= self.textLimit ? .systemGray : .systemRed
            })
            .store(in: &cancellables)
        
        // 엔터 누르면 포커스 해제하고 키보드 내리기
        paperTitleTextField
            .controlPublisher(for: .editingDidEndOnExit)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else {return}
                self.paperTitleTextField.resignFirstResponder()
            })
            .store(in: &cancellables)
        
        // 텍스트 입력을 시작하면 경고 메시지 지우기
        paperTitleTextField
            .controlPublisher(for: .editingDidBegin)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else {return}
                self.setTitleWarningLabel(state: .normal)
            })
            .store(in: &cancellables)
    }
    
    // 제목 경고 라벨 종류 설정하기
    private func setTitleWarningLabel(state: TextState) {
        warningLabelForTitle.setText(text: state.sentence)
        textState = state
        if state == .normal {
            warningLabelForTitle.showView(false)
        } else {
            warningLabelForTitle.showView(true)
        }
    }
    
    // 타이머 경고 라벨 종류 설정하기
    private func setTimerWarningLabel(state: TimerState) {
        warningLabelForTimer.setText(text: state.sentence)
        timerState = state
        if state == .normal {
            warningLabelForTimer.showView(false)
        } else {
            warningLabelForTimer.showView(true)
        }
    }
    
    // 생성하기 버튼 눌렀을 때 경고 메시지 띄워주거나 페이퍼 뷰로 이동하기
    @objc private func createBtnPressed(_ sender: UIBarButtonItem) {
        
        // 글자 경고 라벨 보여주기
        let textCount = paperTitleTextField.text?.count ?? 0
        if textCount == 0 {
            textState = .noText
            paperTitleTextField.resignFirstResponder()
        } else if textCount > textLimit {
            textState = .tooLong
            paperTitleTextField.resignFirstResponder()
        }
        
        // 텍스트 경고 라벨 보여주기
        setTitleWarningLabel(state: textState)
        // 타이머 경고 라벨 설정하기
        setTimerWarningLabel(state: timerState)
        
        if timerState == .normal && textState == .normal {
              input.send(.endSettingPaper)
              NotificationCenter.default.post(
                  name: Notification.Name.viewChange,
                  object: nil,
                  userInfo: [NotificationViewKey.view: "보관함"]
              )
          }
      }
    
    // 뒤로가기 버튼 눌렀을 때 뒤로가기
    @objc private func backBtnPressed() {
        navigationController?.popViewController(animated: true)
    }

    // 배경 눌렀을 때 텍스트필드 포커스 해제하기
    @objc private func backgroundTapped(_ sender: UITapGestureRecognizer) {
        paperTitleTextField.resignFirstResponder()
    }
    
    // 피커 버튼 눌렀을 때 피커 보여주기
    @objc private func onClickedTimePickerButton(_ sender: UIButton) {
        timePicker.modalPresentationStyle = .popover
        timePicker.popoverPresentationController?.sourceView = sender
        present(timePicker, animated: true)
    }
}

// 스냅킷 설정
extension PaperSettingViewController {
    private func configure() {
        view.addSubview(thumbnail)
        view.addSubview(title1)
        view.addSubview(subtitle1)
        view.addSubview(paperTitleTextField)
        view.addSubview(titleLengthLabel)
        view.addSubview(warningLabelForTitle)
        view.addSubview(title2)
        view.addSubview(subtitle2)
        view.addSubview(limitTimeTitle)
        view.addSubview(timePickerButton)
        view.addSubview(warningLabelForTimer)
        thumbnail.addSubview(gradientView)
        thumbnail.addSubview(thumbnailTitle)
        thumbnail.addSubview(thumbnailDescription)
        paperTitleTextField.addSubview(textFieldBorder)
    }
    
    private func setConstraints() {
        gradientView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        thumbnail.snp.makeConstraints({ make in
            make.leading.equalToSuperview().offset(PaperSettingLength.thumbnailLeftMargin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(PaperSettingLength.topMargin)
            make.width.equalTo(PaperSettingLength.thumbnailWidth)
            make.height.equalTo(PaperSettingLength.thumbnailHeight)
        })
        thumbnailDescription.snp.makeConstraints({ make in
            make.bottom.equalToSuperview().offset(-PaperSettingLength.thumbnailBottomPadding)
            make.leading.equalToSuperview().offset(PaperSettingLength.thumbnailLeftPadding)
            make.trailing.equalToSuperview().offset(-PaperSettingLength.thumbnailRightPadding)
        })
        thumbnailTitle.snp.makeConstraints({ make in
            make.bottom.equalTo(thumbnailDescription.snp.top).offset(-PaperSettingLength.thumbnailLabelSpacing)
            make.leading.equalToSuperview().offset(PaperSettingLength.thumbnailLeftPadding)
            make.trailing.equalToSuperview().offset(-PaperSettingLength.thumbnailRightPadding)
        })
        title1.snp.makeConstraints({ make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(PaperSettingLength.topMargin)
            make.leading.equalTo(thumbnail.snp.trailing).offset(PaperSettingLength.sectionLeftMargin)
            make.trailing.equalToSuperview().offset(-PaperSettingLength.sectionRightMargin)
        })
        subtitle1.snp.makeConstraints({ make in
            make.top.equalTo(title1.snp.bottom).offset(PaperSettingLength.sectionTitleBottomMargin)
            make.leading.equalTo(title1)
            make.trailing.equalTo(title1)
        })
        paperTitleTextField.snp.makeConstraints({ make in
            make.top.equalTo(subtitle1.snp.bottom).offset(PaperSettingLength.sectionSubTitleBottomMargin)
            make.leading.equalTo(title1)
            make.trailing.equalTo(titleLengthLabel.snp.leading).offset(-PaperSettingLength.textfieldTitleLengthSpacing)
            make.height.equalTo(PaperSettingLength.textfieldWithBorderHeight)
        })
        titleLengthLabel.snp.makeConstraints({ make in
            make.bottom.equalTo(paperTitleTextField.snp.bottom)
            make.trailing.equalTo(title1)
            make.width.equalTo(PaperSettingLength.titleLengthLabelWidth)
            make.height.equalTo(PaperSettingLength.titleLengthLabelHeight)
        })
        warningLabelForTitle.snp.makeConstraints({ make in
            make.top.equalTo(paperTitleTextField.snp.bottom).offset(PaperSettingLength.warningLabelTopMargin)
            make.leading.equalTo(title1)
        })
        title2.snp.makeConstraints({ make in
            make.top.equalTo(warningLabelForTitle.snp.bottom).offset(PaperSettingLength.sectionSpacing)
            make.leading.equalTo(title1)
            make.trailing.equalTo(title1)
        })
        subtitle2.snp.makeConstraints({ make in
            make.top.equalTo(title2.snp.bottom).offset(PaperSettingLength.sectionTitleBottomMargin)
            make.leading.equalTo(title1)
            make.trailing.equalTo(title1)
        })
        limitTimeTitle.snp.makeConstraints({ make in
            make.top.equalTo(subtitle2.snp.bottom).offset(PaperSettingLength.sectionSubTitleBottomMargin)
            make.leading.equalTo(title1)
        })
        timePickerButton.snp.makeConstraints({ make in
            make.centerY.equalTo(limitTimeTitle)
            make.leading.equalTo(limitTimeTitle.snp.trailing).offset(PaperSettingLength.timePickerLeftMargin)
            make.width.equalTo(PaperSettingLength.timePickerButtonWidth)
            make.height.equalTo(PaperSettingLength.timePickerButtonHeight)
        })
        warningLabelForTimer.snp.makeConstraints({ make in
            make.top.equalTo(timePickerButton.snp.bottom).offset(PaperSettingLength.warningLabelTopMargin)
            make.leading.equalTo(limitTimeTitle)
        })
        textFieldBorder.snp.makeConstraints({ make in
            make.top.equalTo(paperTitleTextField.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(PaperSettingLength.textfieldBorderWidth)
        })
    }
}
