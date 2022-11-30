//
//  TemplateSelectViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/05.
//

import Combine
import UIKit

final class PaperTemplateSelectViewModel {
    private let userDefaultsKey = ["recentTemplate1", "recentTemplate2", "recentTemplate3"]
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()

    enum Input {
        case viewDidAppear
        case newTemplateTap(template: TemplateEnum)
    }
    enum Output {
        case getRecentTemplateSuccess(templates: [TemplateEnum])
        case getRecentTemplateFail
    }
    
    // 최근 선택한 템플릿이 뭔지 유저 디폴트에 저장
    private func saveRecentTemplate(template: TemplateEnum) {
        var recentTemplates = getRecentTemplates()
        
        if let index = recentTemplates.firstIndex(of: template) {
            recentTemplates.remove(at: index)
        }
        
        switch recentTemplates.count {
        case 0:
            UserDefaults.standard.set(template.template.templateString, forKey: userDefaultsKey[2])
            UserDefaults.standard.set("", forKey: userDefaultsKey[1])
            UserDefaults.standard.set("", forKey: userDefaultsKey[0])
        case 1:
            UserDefaults.standard.set(recentTemplates[0].template.templateString, forKey: userDefaultsKey[2])
            UserDefaults.standard.set(template.template.templateString, forKey: userDefaultsKey[1])
            UserDefaults.standard.set("", forKey: userDefaultsKey[0])
        case 2, 3:
            UserDefaults.standard.set(recentTemplates[1].template.templateString, forKey: userDefaultsKey[2])
            UserDefaults.standard.set(recentTemplates[0].template.templateString, forKey: userDefaultsKey[1])
            UserDefaults.standard.set(template.template.templateString, forKey: userDefaultsKey[0])
        default:
            break
        }
    }
    
    // 최근 템플릿이 존재하는지 확인하고 가져오기
    private func getRecentTemplates() -> [TemplateEnum] {
        var recentTemplates = [TemplateEnum]()
        
        for key in userDefaultsKey {
            if
                let recentTemplateString = UserDefaults.standard.value(forKey: key) as? String,
                let template = TemplateEnum(rawValue: recentTemplateString)
            {
                recentTemplates.append(template)
            }
        }
        
        return recentTemplates
    }
    
    // 최근 템플릿에 대한 결과 보내기
    private func sendResult(recentTemplates: [TemplateEnum]) {
        if recentTemplates.count == 0 {
            output.send(.getRecentTemplateFail)
        } else {
            output.send(.getRecentTemplateSuccess(templates: recentTemplates))
        }
    }
    
    // 어떤 행동이 Input으로 들어오면 그것에 맞는 행동을 Output에 저장한 뒤 반환해주기
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input
            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case.viewDidAppear:
                    self.sendResult(recentTemplates: self.getRecentTemplates())
                case .newTemplateTap(let template):
                    self.saveRecentTemplate(template: template)
                    self.sendResult(recentTemplates: self.getRecentTemplates())
                }
            })
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    // 만들어둔 모든 템플릿 가져오기
    func getTemplates() -> [TemplateEnum] {
        let templates = TemplateEnum.allCases
        return templates
    }
}
