//
//  DatabaseManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import FirebaseFirestore
import Combine
import CombineCocoa

enum FireStoreConstants: String {
    case usersCollectionPath = "rollingpaper_users"
    case papersPath = "rollingpaper_papers"
    case paperPreviewsPath = "rollingpaper_paperPreviews"
    case usersNamePath = "rollingpaper_userNames"
}

final class FirestoreManager: DatabaseManager {
    
    static let shared: DatabaseManager = FirestoreManager()
    var papersSubject: CurrentValueSubject<[PaperPreviewModel], Never> = .init([])
    var paperSubject: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    private let database = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var currentUserEmail: String?
    
    private init() {
        bind()
    }
    
    /// 현재 로그인된 유저 프로필 데이터 퍼블리셔 구독: (1). 유저 프로필이 변경될 때 감지 가능 (2). 로드 시 자동으로 현재 로그인된 유저가 작성한 페이퍼 프리뷰 배열을 로드
    private func bind() {
        if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
            self.currentUserEmail = currentUserEmail
            self.loadPaperPreviews()
        }
    }
    
    /// (1). 페이퍼 아이디를 통해 파이어베이스 내 저장된 페이퍼 탐색 및 페이퍼 퍼블리셔에 로드 (2). 페이퍼 아이디에 대한 페이퍼 데이터가 존재하지 않을 때 유저의 페이퍼 프리뷰 배열 업데이트
    func fetchPaper(paperId: String) {
        database
            .collection(FireStoreConstants.papersPath.rawValue)
            .document(paperId)
            .getDocument(completion: { [weak self] document, error in
                guard
                    let data = document?.data(),
                    let paper = self?.getPaper(from: data),
                    error == nil else {
                    self?.removePaperPreview(paperId: paperId)
                    self?.removeUsersPaperId(paperId: paperId)
                    self?.paperSubject.send(nil)
                    return
                }
                self?.paperSubject.send(paper)
            })
    }
    
    func resetPaper() {
        paperSubject.send(nil)
    }
    
    /// (1). 파이어베이스 내 페이퍼 데이터 추가 (2). 현재 유저가 작성한 페이퍼 아이디 목록에 추가 (3). 파이어베이스 내 페이퍼 프리뷰 데이터 추가
    func addPaper(paper: PaperModel) {
        paperSubject.send(paper)
        let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString, thumbnailURLString: paper.thumbnailURLString)
        guard
            currentUserEmail != nil,
            let paperDict = getPaperDict(with: paper) else { return }
        database
            .collection(FireStoreConstants.papersPath.rawValue)
            .document(paper.paperId)
            .setData(paperDict) { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Paper added in Firebase Successfully")
                    self?.setPaperPreview(paperPreview: paperPreview)
                    self?.addUsersPaperId(paperId: paper.paperId)
                    self?.papersSubject.send(self?.papersSubject.value ?? [] + [paperPreview])
                }
            }
    }
    
    /// 현재 작성 중 페이퍼가 있을 때(페이퍼 데이터 퍼블리셔 값이 유효할 때): (1). 파이어베이스 내 페이퍼 데이터 변경 (2). 로컬 페이퍼 데이터 퍼블리셔의 데이터 변경
    func addCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        currentPaper.cards.append(card)
        guard let paperDict = getPaperDict(with: currentPaper) else { return }
        database
            .collection(FireStoreConstants.papersPath.rawValue)
            .document(paperId)
            .setData(paperDict) { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self?.paperSubject.send(currentPaper)
                    print("Card added in Firebase Succesfully")
                }
            }
    }
    
    /// (1). 파이어베이스 내 페이퍼 데이터 삭제 (2). 현재 유저가 작성한 페이퍼 아이디 목록 중 해당 페이퍼 아이디 삭제 (3). 파이어베이스 내 페이퍼 프리뷰 데이터 삭제 (4). 현재 유저의 로컬 페이퍼 프리뷰 데이터 중 해당 페이퍼 삭제
    func removePaper(paperId: String) {
        database
            .collection(FireStoreConstants.papersPath.rawValue)
            .document(paperId)
            .delete(completion: { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self?.removePaperPreview(paperId: paperId)
                    self?.removeUsersPaperId(paperId: paperId)
                    print("Paper Removed in Firebase Successfully")
                }
            })
    }
    
    /// 현재 작성 중 페이퍼가 있을 때(페이퍼 데이터 퍼블리셔 값이 유효할 때): (1). 파이어베이스 내 데이터 변경 (2). 로컬 페이퍼 데이터 퍼블리셔 데이터 변경
    func removeCard(paperId: String, card: CardModel) {
        database
            .collection(FireStoreConstants.papersPath.rawValue)
            .document(paperId)
            .getDocument(completion: { [weak self] document, error in
                guard
                    error == nil,
                    let data = document?.data(),
                    var paper = self?.getPaper(from: data) else {
                    print("Fetch Paper Failed")
                    return
                }
                paper.cards.removeAll(where: {$0.cardId == card.cardId })
                self?.updatePaper(paper: paper)
            })
    }
    
    
    /// (1). 파이어베이스 내 데이터 업데이트 (2). 프리뷰가 변경되었을 때를 대비, 프리뷰 데이터 업데이트, (3) 제목 업데이트
    func updatePaper(paper: PaperModel) {
        guard let paperDict = getPaperDict(with: paper) else { return }
        let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString, thumbnailURLString: paper.thumbnailURLString)
        database
            .collection(FireStoreConstants.papersPath.rawValue)
            .document(paper.paperId)
            .setData(paperDict) { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Paper Updated in Firebase Successfully")
                    self?.setPaperPreview(paperPreview: paperPreview)
                }
            }
    }
    
    /// 현재 작성 중 페이퍼가 있을 때(페이퍼 데이터 퍼블리셔 값이 유효할 때): (1). 파이어베이스 내 페이퍼 업데이트 (2). 로컬 페이퍼 데이터 퍼블리셔 데이터 업데이트
    func updateCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        if let index = currentPaper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
            currentPaper.cards[index] = card
            updatePaper(paper: currentPaper)
        }
    }
}

extension FirestoreManager {
    /// 파이어베이스 내 페이퍼 프리뷰 로드, 페이퍼 프리뷰가 존재하지 않을 경우 현재 유저의 페이퍼 목록 중 페이퍼 아이디를 삭제
    private func fetchPaperPreview(paperId: String) {
        database
            .collection(FireStoreConstants.paperPreviewsPath.rawValue)
            .document(paperId)
            .getDocument(completion: { [weak self] document, error in
                guard
                    let data = document?.data(),
                    let paperPreview = self?.getPaperPreview(from: data),
                    error == nil else {
                    self?.removeUsersPaperId(paperId: paperId)
                    return
                }
                self?.papersSubject.send(self?.papersSubject.value ?? [] + [paperPreview])
            })
    }
    
    /// (1). 파이어베이스 내 페이퍼 프리뷰 삭제 (2). 유저 로컬 페이퍼 프리뷰 데이터 중 해당 페이퍼 프리뷰 데이터 삭제
    private func removePaperPreview(paperId: String) {
        database
            .collection(FireStoreConstants.paperPreviewsPath.rawValue)
            .document(paperId)
            .delete(completion: { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    if var currentPapers = self?.papersSubject.value {
                        currentPapers.removeAll(where: { $0.paperId == paperId })
                        self?.papersSubject.send(currentPapers)
                    }
                    print("PaperPreview Successfully Removed")
                }
            })
    }
    
    /// 파이어베이스 내 프리뷰를 세팅 (설정 및 추가 동일 로직 사용)
    private func setPaperPreview(paperPreview: PaperPreviewModel) {
        guard let paperPreviewDict = getPaperPreviewDict(with: paperPreview) else { return }
        database
            .collection(FireStoreConstants.paperPreviewsPath.rawValue)
            .document(paperPreview.paperId)
            .setData(paperPreviewDict) { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("PaperPreview Successfully Set")
                }
            }
    }
    
    /// 현재 유저의 페이퍼 아이디 딕셔너리에 해당 페이퍼 아이디를 추가
    private func addUsersPaperId(paperId: String) {
        guard let currentUserEmail = currentUserEmail else { return }
        database
            .collection(FireStoreConstants.usersCollectionPath.rawValue)
            .document(currentUserEmail)
            .getDocument(completion: { [weak self] snapshot, error in
                guard
                    error == nil,
                    var dictionary = snapshot?.data() as? [String: [String]],
                    var paperIds = dictionary["paperIds"] else { return }
                paperIds.append(paperId)
                dictionary["paperIds"] = paperIds
                self?.database
                    .collection(FireStoreConstants.usersCollectionPath.rawValue)
                    .document(currentUserEmail)
                    .setData(dictionary, completion: { error in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            print("User's PaperId Added Successfully")
                        }
                    })
            })
    }
    
    /// 현재 유저의 페이퍼 아이디 딕셔너리 내에서 해당 페이퍼 아이디를 삭제
    private func removeUsersPaperId(paperId: String) {
        guard let currentUserEmail = currentUserEmail else { return }
        database
            .collection(FireStoreConstants.usersCollectionPath.rawValue)
            .document(currentUserEmail)
            .getDocument(completion: { [weak self] snapshot, error in
                guard
                    error == nil,
                    var dictionary = snapshot?.data() as? [String: [String]],
                    var paperIds = dictionary["paperIds"] else { return }
                paperIds.removeAll(where: {$0 == paperId })
                dictionary["paperIds"] = paperIds
                self?.database
                    .collection(FireStoreConstants.usersCollectionPath.rawValue)
                    .document(currentUserEmail)
                    .setData(dictionary, completion: { error in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            print("User's PaperId Removed Successfully")
                        }
                    })
            })
    }
    
    /// 현재 유저의 페이퍼 아이디 배열을 바탕으로 페이퍼 프리뷰 데이터를 로드, 데이터 퍼블리셔 내 데이터 추가
    private func loadPaperPreviews() {
        guard let currentUserEmail = currentUserEmail else { return }
        database
            .collection(FireStoreConstants.usersCollectionPath.rawValue)
            .document(currentUserEmail)
            .getDocument(completion: { [weak self] snapshot, error in
                guard
                    error == nil,
                    let dictionary = snapshot?.data() as? [String: [String]],
                    let paperIds = dictionary["paperIds"] else { return }
                paperIds.forEach({ paperId in
                    self?.fetchPaperPreview(paperId: paperId)
                })
            })
    }
    
    /// 페이퍼 모델 데이터를 파이어베이스가 사용하는 딕셔너리 타입으로 인코딩
    private func getPaperDict(with paper: PaperModel) -> [String: Any]? {
        guard
            let paperData = try? JSONEncoder().encode(paper),
            let paperDict = (try? JSONSerialization.jsonObject(with: paperData, options: .fragmentsAllowed)).flatMap({ $0 as? [String: Any] }) else {
            return nil
        }
        return paperDict
    }
    
    /// 페이퍼 프리뷰 모델 데이터를 파이어베이스가 사용하는 딕셔너리 타입으로 인코딩
    private func getPaperPreviewDict(with paperPreview: PaperPreviewModel) -> [String: Any]? {
        guard
            let paperPreviewData = try? JSONEncoder().encode(paperPreview),
            let paperPreviewDict = (try? JSONSerialization.jsonObject(with: paperPreviewData, options: .fragmentsAllowed)).flatMap({ $0 as? [String: Any] }) else {
            return nil
        }
        return paperPreviewDict
    }
    
    /// 딕셔너리 데이터를 페이퍼 데이터로 디코딩
    private func getPaper(from paperDict: [String: Any]) -> PaperModel? {
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: paperDict, options: .fragmentsAllowed),
            let paper = try? JSONDecoder().decode(PaperModel.self, from: jsonData) else {
            return nil
        }
        return paper
    }
    
    /// 딕셔너리 데이터를 페이퍼 프리뷰 데이터로 디코딩
    private func getPaperPreview(from paperPreviewDict: [String: Any]) -> PaperPreviewModel? {
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: paperPreviewDict, options: .fragmentsAllowed),
            let paperPreview = try? JSONDecoder().decode(PaperPreviewModel.self, from: jsonData) else {
            return nil
        }
        return paperPreview
    }
}
