//
//  TemplateSelectViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/05.
//

import UIKit

final class TemplateSelectViewModel {
    
    func getRecentTemplate() -> TemplateEnum? {
        // TODO: 최근 템플릿 받아오기
        let recentTemplate: TemplateEnum = .grid
        return recentTemplate
    }
    
    func getTemplates() -> [TemplateEnum] {
        // TODO: 현재 존재하는 템플릿 받아오기
        let templates: [TemplateEnum] = [.halloween, .grid, .sunrise, .halloween, .grid, .sunrise, .halloween, .grid, .sunrise, .halloween]
        return templates
    }
}
