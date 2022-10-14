//
//  LocalDatabaseManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import Combine

protocol DatabaseManager {
    static var shared: DatabaseManager { get }
    var papersSubject: CurrentValueSubject<[PaperPreviewModel], Never> { get set }
    var paperSubject: CurrentValueSubject<PaperModel?, Never> { get set }
    func fetchPaper(paperId: String)
    func resetPaper()
    func addPaper(paper: PaperModel)
    func addCard(paperId: String, card: CardModel)
    func removePaper(paperId: String)
    func removeCard(paperId: String, card: CardModel)
    func updatePaper(paper: PaperModel)
    func updateCard(paperId: String, card: CardModel)
    func isValidUserName(with userName: String) -> AnyPublisher<Bool, Never>
    func setUserName(from oldName: String?, to newName: String) -> AnyPublisher<Bool, Never>
}
