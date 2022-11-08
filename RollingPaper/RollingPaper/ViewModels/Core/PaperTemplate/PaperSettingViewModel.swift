//
//  SetRoomViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/07.
//

import UIKit
import Combine

class PaperSettingViewModel {
    private var paperTitle: String = ""
    private var paperDurationHour: Int = 2
    private var template: TemplateEnum
    private let databaseManager: DatabaseManager
    
    let authManager: AuthManager = FirebaseAuthManager.shared
    var currentUser: UserModel?
    
    init(databaseManager: DatabaseManager = LocalDatabaseFileManager.shared, template: TemplateEnum) {
        self.databaseManager = databaseManager
        self.template = template
        //처음에 로그인 한 상태로 생성하기 버튼을 눌렀을 떄 페이퍼의 creator를 넣어주기 위함
        setCurrentPaperCreator()
    }
    
    enum Input {
        case setPaperTitle(title: String)
        case endSettingPaper
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // 어떤 행동이 Input으로 들어오면 그것에 맞는 행동을 Output에 저장한 뒤 반환해주기
    func transform(input: AnyPublisher<Input, Never>) {
        input
//            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .setPaperTitle(let title):
                    self.setPaperTitle(title: title)
                case .endSettingPaper:
                    self.createPaper()
                }
            })
            .store(in: &cancellables)
    }
    
    // 페이퍼 제목 설정하기
    private func setPaperTitle(title: String) {
        self.paperTitle = title
    }
    
    // 페이퍼 만들기
    private func createPaper() {
        let currentTime = Date()
        guard let endTime = Calendar.current.date(byAdding: .hour, value: paperDurationHour, to: currentTime) else {
            return
        }
        let paper = PaperModel(creator: currentUser, cards: [], date: currentTime, endTime: endTime, title: self.paperTitle, templateString: template.template.templateString)
        databaseManager.addPaper(paper: paper)
        databaseManager.fetchPaper(paperId: paper.paperId)
    }
    
    private func setCurrentPaperCreator() {
        authManager
            .userProfileSubject
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] userProfile in
                self?.currentUser = userProfile
            }
            .store(in: &cancellables)
    }
}