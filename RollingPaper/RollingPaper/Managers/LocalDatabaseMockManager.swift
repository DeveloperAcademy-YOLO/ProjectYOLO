//
//  LocalDatabaseMockManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/08.
//

import Foundation
import Combine

final class LocalDatabaseMockManager: LocalDatabaseManager {
    static var shared: LocalDatabaseManager
    
    var papersSubject: CurrentValueSubject<[PaperModel], Never>
    
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


