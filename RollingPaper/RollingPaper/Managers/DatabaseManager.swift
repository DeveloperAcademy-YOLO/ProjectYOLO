//
//  LocalDatabaseManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import Combine

// TODO: cardSubject transaction timing issue with papersSubject

protocol DatabaseManager {
    static var shared: DatabaseManager { get }
    var papersSubject: CurrentValueSubject<[PaperModel], Never> { get set }
    var cardsSubject: CurrentValueSubject<[CardModel], Never> { get set }
    func addPaper(paper: PaperModel)
    func addCard(paperId: String, card: CardModel)
    func removePaper(paper: PaperModel)
    func removeCard(paperId: String, card: CardModel)
    func updatePaper(paper: PaperModel)
    func updateCard(paperId: String, card: CardModel)
    func addPaperObserver(paperId: String)
}
