//
//  SetRoomViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/07.
//

import UIKit
import SnapKit
import Combine

private class Length {
    static let topMargin: CGFloat = 48
    static let thumbnailLeftMargin: CGFloat = 48
    static let thumbnailRadius: CGFloat = 24
    static let thumbnailWidth: CGFloat = 262
    static let thumbnailHeight: CGFloat = 388
    static let thumbnailLeftPadding: CGFloat = 24
    static let thumbnailRightPadding: CGFloat = 24
    static let thumbnailBottomPadding: CGFloat = 28
    static let thumbnailLabelSpacing: CGFloat = 8
    static let sectionLeftMargin: CGFloat = 36
    static let sectionRightMargin: CGFloat = 88
    static let sectionTitleBottomMargin: CGFloat = 14
    static let sectionSubTitleBottomMargin: CGFloat = 32
    static let sectionSpacing: CGFloat = 48
    static let textfieldHeight: CGFloat = 15
    static let textfieldWithBorderSpacing: CGFloat = 9
    static let textfieldBorderWidth: CGFloat = 2
    static let textfieldWithBorderHeight: CGFloat = textfieldHeight + textfieldWithBorderSpacing + textfieldBorderWidth
    static let textfieldTitleLengthSpacing: CGFloat = 10
    static let titleLengthLabelWidth: CGFloat = 60
    static let titleLengthLabelHeight: CGFloat = 28
}

class PaperSettingViewController: UIViewController {
    private let textLimit = 30
    private let template: TemplateEnum
    private let paperTitleTextField = UITextField()
    private let titleLengthLabel = UILabel()
    private let input: PassthroughSubject<PaperSettingViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: PaperSettingViewModel
    
    private var currentPaperTitle: String = ""
    
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
        setMainView()
        setNavigationBar()
        bind()
    }
    
    // Input이 설정될때마다 자동으로 transform 함수가 실행되고 그 결과값으로 Output이 오면 어떤 행동을 할지 정하기
    private func bind() {
        viewModel.transform(input: input.eraseToAnyPublisher())
    }
    
    // 네비게이션 바 초기화
    private func setNavigationBar() {
        // 요셉이 만들어주신 거 그대로 쓰긴 했는데, 나중에 크기와 색깔을 전부 통일해야할듯함 (티모가 따로 디자인해주신 버튼이 아니라면)
        let customBackBtnImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(named: "customBlack") ?? UIColor(red: 100, green: 100, blue: 100), renderingMode: .alwaysOriginal)
        let leftCustomBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        leftCustomBackBtn.setTitle("템플릿", for: .normal)
        leftCustomBackBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        leftCustomBackBtn.setTitleColor(.black, for: .normal)
        leftCustomBackBtn.setImage(customBackBtnImage, for: .normal)
        leftCustomBackBtn.addLeftPadding(5)
        leftCustomBackBtn.addTarget(self, action: #selector(backBtnPressed), for: .touchUpInside)
        
        let righCustomCreateBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        righCustomCreateBtn.setTitle("생성하기", for: .normal)
        righCustomCreateBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        righCustomCreateBtn.setTitleColor(.black, for: .normal)
        righCustomCreateBtn.addTarget(self, action: #selector(createBtnPressed), for: .touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftCustomBackBtn)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: righCustomCreateBtn)
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .systemBackground
        
        let thumbnail = UIImageView()
        let thumbnailTitle = UILabel()
        let thumbnailDescription = UILabel()
        let title1 = getTitle(text: "롤링페이퍼 제목")
        let subtitle1 = getSubTitle(text: "누가 이 롤링페이퍼를 받게 되는지, 왜 받는지를 포함해서 적어주세요")
        let title2 = getTitle(text: "타이머 설정")
        let subtitle2 = getSubTitle(text: "타이머가 종료되면 더이상 롤링페이퍼 내용을 작성하거나 편집할 수 없게 됩니다")
        
        setTextField(placeHolder: "재현이의 중학교 졸업을 축하하며")
        setTextLengthView()
        
        view.addSubview(thumbnail)
        view.addSubview(title1)
        view.addSubview(subtitle1)
        view.addSubview(paperTitleTextField)
        view.addSubview(titleLengthLabel)
        view.addSubview(title2)
        view.addSubview(subtitle2)
        thumbnail.addSubview(thumbnailTitle)
        thumbnail.addSubview(thumbnailDescription)
        
        thumbnail.layer.masksToBounds = true
        thumbnail.layer.cornerRadius = Length.thumbnailRadius
        thumbnail.image = template.template.thumbnailDetail
        thumbnail.snp.makeConstraints({ make in
            make.leading.equalToSuperview().offset(Length.thumbnailLeftMargin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Length.topMargin)
            make.width.equalTo(Length.thumbnailWidth)
            make.height.equalTo(Length.thumbnailHeight)
        })
        
        thumbnailDescription.text =  template.template.templateDescription
        thumbnailDescription.textColor = .white
        thumbnailDescription.numberOfLines = 0
        thumbnailDescription.font = .preferredFont(forTextStyle: .body)
        thumbnailDescription.snp.makeConstraints({ make in
            make.bottom.equalToSuperview().offset(-Length.thumbnailBottomPadding)
            make.leading.equalToSuperview().offset(Length.thumbnailLeftPadding)
            make.trailing.equalToSuperview().offset(-Length.thumbnailRightPadding)
        })
        
        thumbnailTitle.text = template.template.templateTitle
        thumbnailTitle.textColor = .white
        thumbnailTitle.numberOfLines = 0
        thumbnailTitle.font = .preferredFont(for: .title2, weight: .bold)
        thumbnailTitle.snp.makeConstraints({ make in
            make.bottom.equalTo(thumbnailDescription.snp.top).offset(-Length.thumbnailLabelSpacing)
            make.leading.equalToSuperview().offset(Length.thumbnailLeftPadding)
            make.trailing.equalToSuperview().offset(-Length.thumbnailRightPadding)
        })
        
        title1.snp.makeConstraints({ make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Length.topMargin)
            make.leading.equalTo(thumbnail.snp.trailing).offset(Length.sectionLeftMargin)
            make.trailing.equalToSuperview().offset(-Length.sectionRightMargin)
        })
        subtitle1.snp.makeConstraints({ make in
            make.top.equalTo(title1.snp.bottom).offset(Length.sectionTitleBottomMargin)
            make.leading.equalTo(title1)
            make.trailing.equalTo(title1)
        })
        paperTitleTextField.snp.makeConstraints({ make in
            make.top.equalTo(subtitle1.snp.bottom).offset(Length.sectionSubTitleBottomMargin)
            make.leading.equalTo(title1)
            make.trailing.equalTo(titleLengthLabel.snp.leading).offset(-Length.textfieldTitleLengthSpacing)
            make.height.equalTo(Length.textfieldWithBorderHeight)
        })
        titleLengthLabel.snp.makeConstraints({ make in
            make.bottom.equalTo(paperTitleTextField.snp.bottom)
            make.trailing.equalTo(title1)
            make.width.equalTo(Length.titleLengthLabelWidth)
            make.height.equalTo(Length.titleLengthLabelHeight)
        })
        title2.snp.makeConstraints({ make in
            make.top.equalTo(paperTitleTextField.snp.bottom).offset(Length.sectionSpacing)
            make.leading.equalTo(title1)
            make.trailing.equalTo(title1)
        })
        subtitle2.snp.makeConstraints({ make in
            make.top.equalTo(title2.snp.bottom).offset(Length.sectionTitleBottomMargin)
            make.leading.equalTo(title1)
            make.trailing.equalTo(title1)
        })
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(gesture)
    }
    
    // 제목 뷰 가져오기
    private func getTitle(text: String) -> UILabel {
        let title = UILabel()
        title.text = text
        title.textColor = .label
        title.font = .preferredFont(forTextStyle: .title2)
        title.numberOfLines = 0
        return title
    }
    
    // 부제목 뷰 가져오기
    private func getSubTitle(text: String) -> UILabel {
        let title = UILabel()
        title.text = text
        title.textColor = .secondaryLabel
        title.font = .preferredFont(forTextStyle: .body)
        title.numberOfLines = 0
        return title
    }
    
    // 텍스트필드 뷰 가져오기
    private func setTextField(placeHolder: String) {
        let border = UIView()
        paperTitleTextField.addSubview(border)
        paperTitleTextField.attributedPlaceholder = NSAttributedString(string: placeHolder, attributes: [.foregroundColor: UIColor.placeholderText])
        paperTitleTextField.delegate = self
        
        // 제목 입력할때마다 입력한 글자 저장
        paperTitleTextField
            .controlPublisher(for: .editingChanged)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else {return}
                self.input.send(.setPaperTitle(title: self.paperTitleTextField.text ?? ""))
                self.titleLengthLabel.text = "\(self.paperTitleTextField.text?.count ?? 0)/\(self.textLimit)"
                self.titleLengthLabel.backgroundColor = (self.paperTitleTextField.text?.count ?? 0) < self.textLimit ? .systemGray : .systemRed
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
    
        border.backgroundColor = .opaqueSeparator
        border.snp.makeConstraints({ make in
            make.top.equalTo(paperTitleTextField.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Length.textfieldBorderWidth)
        })
    }
    
    // 텍스트 글자 수 보여주는 뷰 세팅하기
    private func setTextLengthView() {
        titleLengthLabel.text = "0/\(textLimit)"
        titleLengthLabel.font = UIFont.preferredFont(for: .body, weight: .semibold)
        titleLengthLabel.textAlignment = .center
        titleLengthLabel.textColor = .white
        titleLengthLabel.backgroundColor = .systemGray
        titleLengthLabel.layer.cornerRadius = 9
        titleLengthLabel.layer.masksToBounds = true
    }
    
    func setCurrentPaperTitle() {
        currentPaperTitle = paperTitleTextField.text ?? "제목을 입력하지 않으셨습니다."
    }
    
    // 생성하기 버튼 눌렀을 때 동작
    @objc private func createBtnPressed(_ sender: UIBarButtonItem) {
          if paperTitleTextField.text == "" {
              let alert = UIAlertController(title: "잠깐!", message: "페이퍼 제목을 입력해주세요.", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (_: UIAlertAction!) in
                  alert.dismiss(animated: true, completion: nil)
                 }))
              present(alert, animated: true)
          } else {
              input.send(.endSettingPaper)
              NotificationCenter.default.post(
                  name: Notification.Name.viewChange,
                  object: nil,
                  userInfo: [NotificationViewKey.view: "페이퍼 보관함"]
              )
          }
      }
    
    // 뒤로가기 버튼 눌렀을 때 동작
    @objc private func backBtnPressed() {
        navigationController?.popViewController(animated: true)
    }

    // 배경 눌렀을 때 동작
    @objc func backgroundTapped(_ sender: UITapGestureRecognizer) {
        paperTitleTextField.resignFirstResponder()
    }
}

// 텍스트 길이 제한
extension PaperSettingViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        return newString.count <= textLimit
    }
}
