//
//  LocalDatabaseMockManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/08.
//

import Foundation
import Combine
import UIKit

final class LocalDatabaseMockManager: DatabaseManager {
    static let shared: DatabaseManager = LocalDatabaseMockManager()
    private var papersMockData = [PaperModel]()
    private var cancellables = Set<AnyCancellable>()
    var papersSubject: CurrentValueSubject<[PaperPreviewModel], Never> = .init([])
    var paperSubject: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    
    private init() {
        // Set originally set data as default paper data
        loadPapers()
    }
    
    private func loadPapers() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        var paper1 = PaperModel(cards: [], date: today, endTime: tomorrow, title: "MockPaper1", templateString: TemplateEnum.halloween.rawValue)
        var paper2 = PaperModel(cards: [], date: today, endTime: tomorrow, title: "MockPaper2", templateString: TemplateEnum.grid.rawValue)
        if
            let mockImage = UIImage(systemName: "person"),
            let mockData = mockImage.jpegData(compressionQuality: 0.8) {
            let card1 = CardModel(date: Date(), content: mockData)
            let card2 = CardModel(date: Date(), content: mockData)
            let card3 = CardModel(date: Date(), content: mockData)
            let card4 = CardModel(date: Date(), content: mockData)
            paper1.cards.append(contentsOf: [card1, card2])
            paper2.cards.append(contentsOf: [card3, card4])
            papersMockData.append(contentsOf: [paper1, paper2])
        }
        var paperPreviews = [PaperPreviewModel]()
        for paper in papersMockData {
            let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString)
            paperPreviews.append(paperPreview)
        }
        papersSubject.send(paperPreviews)
    }
    
    func addPaper(paper: PaperModel) {
        let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString)
        papersSubject.send(papersSubject.value + [paperPreview])
        papersMockData.append(paper)
    }
    
    func addCard(paperId: String, card: CardModel) {
        // 현재 paperSubject에 카드 추가하기
        guard var currentPaper = paperSubject.value else { return }
        currentPaper.cards.append(card)
        paperSubject.send(currentPaper)
    }
    
    func removePaper(paperId: String) {
        var currentPapers = papersSubject.value
        if let index = currentPapers.firstIndex(where: { $0.paperId == paperId }) {
            currentPapers.remove(at: index)
            papersMockData.removeAll(where: { $0.paperId == paperId })
            papersSubject.send(currentPapers)
        }
    }
    
    func removeCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        if let index = currentPaper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
            currentPaper.cards.remove(at: index)
            paperSubject.send(currentPaper)
        }
    }
    
    func updatePaper(paper: PaperModel) {
        if let index = papersMockData.firstIndex(where: { $0.paperId == paper.paperId }) {
            papersMockData[index] = paper
            var currentPapers = papersSubject.value
            if let previewIndex = currentPapers.firstIndex(where: { $0.paperId == paper.paperId }) {
                currentPapers[previewIndex].thumbnailURLString = paper.thumbnailURLString
            }
        }
    }
    
    func updateCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        if let index = currentPaper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
            currentPaper.cards.remove(at: index)
            paperSubject.send(currentPaper)
        }
    }
    
    func addPaperObserver(paperId: String) {
        // 특정 페이퍼의 값 변경을 감지 -> 로직 구현
    }
    
    func fetchPaper(paperId: String) {
        if let index = papersMockData.firstIndex(where: {$0.paperId == paperId }) {
            let currentPaper = papersMockData[index]
            paperSubject.send(currentPaper)
        }
    }
}
