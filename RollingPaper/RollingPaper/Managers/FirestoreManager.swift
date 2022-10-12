//
//  DatabaseManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import FirebaseFirestore
import Combine

final class FirestoreManager: DatabaseManager {
    static let shared: DatabaseManager = FirestoreManager()
    var cardsSubject: CurrentValueSubject<[CardModel], Never> = .init([])
    var papersSubject: CurrentValueSubject<[PaperModel], Never> = .init([])
    private let database = Firestore.firestore()
    
    private init() {
        loadPapers()
    }
    
    private func loadPapers() {
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
    
    func addPaperObserver(paperId: String) {
        // 특정 document (특정 페이퍼 데이터를 가지고 있는 파이어베이스 파이어스토어) 데이터 변경을 감지
    }
}
