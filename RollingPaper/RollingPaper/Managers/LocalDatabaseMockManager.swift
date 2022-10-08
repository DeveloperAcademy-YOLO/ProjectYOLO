//
//  LocalDatabaseMockManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/08.
//

import Foundation
import Combine
import UIKit

final class LocalDatabaseMockManager: LocalDatabaseManager {
    static let shared: LocalDatabaseManager = LocalDatabaseMockManager()
    
    var papersSubject: CurrentValueSubject<[PaperModel], Never> = .init([])
    
    private init() {
        // Set originally set data as default paper data
        loadPapers()
    }
    
    private func loadPapers() {
        var papers = [PaperModel]()
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        var paper1 = PaperModel(cards: [], date: Date(), endTime: tomorrow, title: "MockPaper1", templateString: TemplateEnum.halloween.rawValue)
        var paper2 = PaperModel(cards: [], date: Date(), endTime: tomorrow, title: "MockPaper2", templateString: TemplateEnum.grid.rawValue)
        if
            let mockImage = UIImage(systemName: "person"),
            let mockData = mockImage.jpegData(compressionQuality: 0.8) {
            let card1 = CardModel(date: Date(), content: mockData)
            let card2 = CardModel(date: Date(), content: mockData)
            let card3 = CardModel(date: Date(), content: mockData)
            let card4 = CardModel(date: Date(), content: mockData)
            paper1.cards.append(contentsOf: [card1, card2])
            paper2.cards.append(contentsOf: [card3, card4])
            papers.append(contentsOf: [paper1, paper2])
        }
    }
    
    func addPaper(paper: PaperModel) {
    }
    
    func addCard(paperId: String, card: CardModel) {
    }
    
    func removePaper(paper: PaperModel) {
    }
    
    func removeCard(paperId: String, card: CardModel) {
    }
    
    func updatePaper(paper: PaperModel) {
    }
    
    func updateCard(paperId: String, card: CardModel) {
    }
}


