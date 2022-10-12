//
//  SetRoomViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/07.
//

import UIKit
import Combine

class SetPaperViewModel {
    private var paperTitle: String = ""
    private var paperDurationHour: Int = 2
    private var template: TemplateEnum
    private let databaseManager: LocalDatabaseManager
    
    init(databaseManager: LocalDatabaseManager = LocalDatabaseMockManager.shared, template: TemplateEnum) {
        self.databaseManager = databaseManager
        self.template = template
    }
    
    enum Input {
        case setPaperTitle(title: String)
        case endSettingPaper
    }
    
    enum Output {
        case createPaperSuccess(paper: PaperModel)
        case createPaperFail
    }
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    // 어떤 행동이 Input으로 들어오면 그것에 맞는 행동을 Output에 저장한 뒤 반환해주기
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else {return}
            switch event {
            case .setPaperTitle(let title):
                self.setPaperTitle(title: title)
            case .endSettingPaper:
                self.createPaper()
            }
        })
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    // 페이퍼 제목 설정하기
    private func setPaperTitle(title: String) {
        paperTitle = title
    }
    
    // 페이퍼 만들기
    private func createPaper() {
        let currentTime = Date()
        guard let endTime = Calendar.current.date(byAdding: .hour, value: paperDurationHour, to: currentTime) else {
            output.send(.createPaperFail)
            return
        }
        let paper = PaperModel(cards: [], date: currentTime, endTime: endTime, title: paperTitle, templateString: template.template.templateString)
        databaseManager.addPaper(paper: paper)
        output.send(.createPaperSuccess(paper: paper))
    }
}
