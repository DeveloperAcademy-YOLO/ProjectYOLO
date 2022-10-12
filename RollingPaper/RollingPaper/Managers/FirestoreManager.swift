//
//  DatabaseManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import Combine

final class FirestoreManager: DatabaseManager {
        
    static let shared: DatabaseManager = FirestoreManager()
    
    var cardsSubject: CurrentValueSubject<[CardModel], Never> = .init([])

    var papersSubject: CurrentValueSubject<[PaperModel], Never> = .init([])
    
    private init() {
        loadPapers()
        addObserverListener()
    }
    
    private func loadPapers() {
        
    }
    
    private func addObserverListener() {
        
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
