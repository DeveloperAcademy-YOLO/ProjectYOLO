//
//  PaperStorageViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/12.
//

import UIKit
import Combine

class PaperStorageViewModel {
    enum Input {
        case viewDidAppear
    }
    enum Output {
        case papersAreUpdated(openedPapers: [PaperModel], closedPapers: [PaperModel])
    }
    
    private let databaseManager: LocalDatabaseManager
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var papers: [PaperModel]?
    
    init(databaseManager: LocalDatabaseManager = LocalDatabaseMockManager.shared) {
        self.databaseManager = databaseManager
        bind()
    }
    
    // 뷰가 나타났다는 시그널이 오면 Paper 목록 보내주기
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else {return}
            switch event {
            case.viewDidAppear:
                let separated = self.separatePapers()
                self.output.send(.papersAreUpdated(openedPapers: separated.0, closedPapers: separated.1))
            }
        })
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    // 데이터베이스 메니저와 연동
    // Paper 목록이 바뀔때마다 업데이트된 목록 보내주기
    private func bind() {
        databaseManager.papersSubject
            .sink(receiveValue: { [weak self] papers in
                guard let self = self else {return}
                self.papers = papers
                
                let separated = self.separatePapers()
                self.output.send(.papersAreUpdated(openedPapers: separated.0, closedPapers: separated.1))
            })
            .store(in: &cancellables)
    }
    
    // 진행중인 페이퍼와 종료된 페이퍼 구분해주기
    private func separatePapers() -> ([PaperModel], [PaperModel]) {
        guard let papers = papers else {return ([], [])}
        var openedPapers = [PaperModel]()
        var closedPapers = [PaperModel]()
        for paper in papers {
            if paper.endTime > Date() {
                openedPapers.append(paper)
            } else {
                closedPapers.append(paper)
            }
        }
        return (openedPapers, closedPapers)
    }
    
}
