//
//  SetRoomViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/07.
//

import Combine
import UIKit

class PaperSettingViewModel {
    static let defaultTime = "1시간 00분"
    
    private let databaseManager: DatabaseManager
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private let authManager: AuthManager = FirebaseAuthManager.shared
    private var paperTitle: String = ""
    private var paperDurationHour: Int = 2
    private var template: TemplateEnum
    private var currentUser: UserModel?
    private var selectedTime: String = defaultTime
        
    enum Input {
        case setPaperTitle(title: String)
        case endSettingPaper
        case timePickerChange(time: String)
    }
    
    enum Output {
        case timePickerChange(time: String)
    }
    
    init(databaseManager: DatabaseManager = LocalDatabaseFileManager.shared, template: TemplateEnum) {
        self.databaseManager = databaseManager
        self.template = template
        //처음에 로그인 한 상태로 생성하기 버튼을 눌렀을 떄 페이퍼의 creator를 넣어주기 위함
        setCurrentPaperCreator()
    }
    
    // 형식 계산해서 종료 시간 반환해주기
    private func getPaperEndTime(duration: String) -> Date {
        let hour = Int(duration.substring(start: 0, end: 1)) ?? 0
        let minute = Int(duration.substring(start: 4, end: 6)) ?? 0
        let totalMinute = hour*60+minute
        return Calendar.current.date(byAdding: .minute, value: totalMinute, to: Date()) ?? Date()
    }
    
    // 페이퍼 제목 설정하기
    private func setPaperTitle(title: String) {
        self.paperTitle = title
    }
    
    // 페이퍼 만들기
    private func createPaper() {
        let endTime = getPaperEndTime(duration: selectedTime)
        let paper = PaperModel(creator: currentUser, cards: [], date: Date(), endTime: endTime, title: self.paperTitle, templateString: template.template.templateString)
        databaseManager.addPaper(paper: paper)
        databaseManager.fetchPaper(paperId: paper.paperId)
    }
    
    // 현재 유저정보를 불러오기
    private func setCurrentPaperCreator() {
        authManager
            .userProfileSubject
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] userProfile in
                self?.currentUser = userProfile
            }
            .store(in: &cancellables)
    }
    
    // 어떤 행동이 Input으로 들어오면 그것에 맞는 행동을 Output에 저장한 뒤 반환해주기
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .setPaperTitle(let title):
                    self.setPaperTitle(title: title)
                case .endSettingPaper:
                    self.createPaper()
                case .timePickerChange(let time):
                    self.selectedTime = time
                    self.output.send(.timePickerChange(time: time))
                }
            })
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
}
