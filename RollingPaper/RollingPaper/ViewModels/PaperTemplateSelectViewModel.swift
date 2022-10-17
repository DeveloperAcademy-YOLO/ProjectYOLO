//
//  TemplateSelectViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/05.
//

import UIKit
import Combine

class PaperTemplateSelectViewModel {
    
    enum Input {
        case viewDidAppear
        case newTemplateTap(template: TemplateEnum)
    }
    
    enum Output {
        case getRecentTemplateSuccess(template: TemplateEnum)
        case getRecentTemplateFail
    }
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    // 어떤 행동이 Input으로 들어오면 그것에 맞는 행동을 Output에 저장한 뒤 반환해주기
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else {return}
            switch event {
            case.viewDidAppear:
                self.getRecentTemplate()
            case .newTemplateTap(let template):
                self.saveRecentTemplate(template: template)
                self.getRecentTemplate()
            }
        })
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }

    // 최근 선택한 템플릿이 뭔지 유저 디폴트에 저장
    private func saveRecentTemplate(template: TemplateEnum) {
        UserDefaults.standard.set(template.template.templateString, forKey: "recentTemplate")
    }
    
    // 최근 템플릿이 존재하는지 확인하고 가져오기
    private func getRecentTemplate() {
        if let recentTemplateString = UserDefaults.standard.value(forKey: "recentTemplate") as? String,
           let template = TemplateEnum(rawValue: recentTemplateString) {
            output.send(.getRecentTemplateSuccess(template: template))
        } else {
            output.send(.getRecentTemplateFail)
        }
    }
    
    // 만들어둔 모든 템플릿 가져오기
    func getTemplates() -> [TemplateEnum] {
        let templates = TemplateEnum.allCases
        return templates
    }
}
