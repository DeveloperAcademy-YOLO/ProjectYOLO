//
//  CardRootViewModel.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/12.
//

import UIKit
import Combine

class CardViewModel {
    
    let currentCard: CurrentValueSubject<CardModel?, Never> = .init(nil)

    private var card = [CardModel]()
    
    
    let localDatabaseManager: DatabaseManager
    let serverDatabaseManager: DatabaseManager
    
    init(localDatabaseManager: DatabaseManager = LocalDatabaseFileManager.shared, serverDatabaseManager: DatabaseManager = FirestoreManager.shared) {
        self.localDatabaseManager = localDatabaseManager
        self.serverDatabaseManager = serverDatabaseManager
    }
    
    enum Input {
        case viewDidLoad
        case resultShown
        case setCardBackgroundImg(background: UIImage) //CardBackgroundViewController 으로부터 backgroundImgGet
        case setCardResultImg(result: UIImage) //CardPencilKitViewController 으로부터 mergedImageSet
        case resultSend(paperID: String, isLocalDB: Bool)
    }
    
    enum Output {
        case getRecentCardBackgroundImgSuccess(background: UIImage?)
        case getRecentCardBackgroundImgFail
        case getRecentCardResultImgSuccess(result: UIImage?)
        case getRecentCardResultImgFail
        //case getPaperID
    }
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else {return}
            switch event {
            case.viewDidLoad:
                self.getRecentCardBackgroundImg()
                self.getRecentCardResultImg()
            case.setCardBackgroundImg(let background):
                self.setCardBackgroundImg(background: background)
                self.getRecentCardBackgroundImg()
            case.setCardResultImg(let result):
                self.setCardResultImg(result: result)
                self.getRecentCardResultImg()
            case.resultShown:
                self.getRecentCardResultImg()
            case.resultSend(let paperID, let isLocalDB):
                print("resultSend Good!!!!!!!")
                self.createCard(paperID: paperID, isLocalDB: isLocalDB)
            }
        })
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func setCardBackgroundImg(background: UIImage) {
        guard let jpeg = background.jpegData(compressionQuality: 1)
        else { return }
        UserDefaults.standard.set(jpeg, forKey: "cardBackgroundImg")
    }
    
    private func getRecentCardBackgroundImg() {
        if let recentBackgroundImg = UserDefaults.standard.data(forKey: "cardBackgroundImg") {
            let backImg = UIImage(data: recentBackgroundImg)
            output.send(.getRecentCardBackgroundImgSuccess(background: backImg))
        } else {
            output.send(.getRecentCardBackgroundImgFail)
        }
    }
    
    private func setCardResultImg(result: UIImage) {
        guard let result = result.jpegData(compressionQuality: 0.2)
        else { return }
        UserDefaults.standard.set(result, forKey: "cardResultImg")
    }
    
    private func createCard(paperID: String, isLocalDB: Bool) {
        print("card view model에서 보냄 \(isLocalDB)")
        guard let recentResultImg = UserDefaults.standard.data(forKey: "cardResultImg")
        else { return }
        
        
//        FirebaseStorageManager.uploadData(dataId: self.currentCard.value?.cardId ?? "", data: recentResultImg, contentType: .jpeg, pathRoot: .card)
        
        
        print("Local Paper Cell count: \(localDatabaseManager.paperSubject.value?.cards.count)")
        let currentTime = Date()
        let resultCard = CardModel(date: currentTime, contentURLString: "") // TODO:
        if isLocalDB {
            localDatabaseManager.addCard(paperId: paperID, card: resultCard)
        } else {
            serverDatabaseManager.addCard(paperId: paperID, card: resultCard)
        }
    }
    
    private func getRecentCardResultImg() {
        if let recentResultImg = UserDefaults.standard.data(forKey: "cardResultImg") {
            let resultImg = UIImage(data: recentResultImg)
            output.send(.getRecentCardResultImgSuccess(result: resultImg))
        } else {
            output.send(.getRecentCardResultImgFail)
        }
    }
}
