//
//  CardRootViewModel.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/12.
//

import UIKit
import Combine

class CardViewModel {
    var cardBackgroundImg = UIImage(named: "Rectangle")
    var cardResultImg = UIImage(named: "heart.fill")
    
    enum Input {
        case viewDidLoad
        case resultShown
        case setCardBackgroundImg(background: UIImage) //CardBackgroundViewController 으로부터 backgroundImgGet
        case setCardResultImg(result: UIImage) //CardPencilKitViewController 으로부터 mergedImageSet
    }
    
    enum Output {
        case getRecentCardBackgroundImgSuccess(background: UIImage?)
        case getRecentCardBackgroundImgFail
        case getRecentCardResultImgSuccess(result: UIImage?)
        case getRecentCardResultImgFail
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
        guard let png = result.pngData()
        else { return }// png로 바꿔서 넣어 버린다.
        UserDefaults.standard.set(png, forKey: "cardResultImg")
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
