//
//  CardResultViewModel.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/18.
//

import UIKit
import Combine

class CardResultViewModel {
    var cardResultImg = UIImage(named: "Rectangle")
    
    enum Input {
        case viewDidLoad
        case setCardResultImg(result: UIImage) //CardPencilKitViewController 으로부터 mergedImageSet
    }
    
    enum Output {
        case getRecentCardResultImgSuccess(result: UIImage)
        case getRecentCardResultImgFail
    }
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else {return}
            switch event {
            case.viewDidLoad:
                self.getRecentCardResultImg()
            case.setCardResultImg(let result):
                self.setCardResultImg(result: result)
                self.getRecentCardResultImg()
            }
        })
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func setCardResultImg(result: UIImage) {
        guard let png = result.pngData()
        else { return }// png로 바꿔서 넣어 버린다.
        UserDefaults.standard.set(png, forKey: "cardResultImg")
    }
    
    private func getRecentCardResultImg() {
        if let recentResultImg = UserDefaults.standard.data(forKey: "cardResultImg") {
            let resultImg = UIImage(data: recentResultImg)
            output.send(.getRecentCardResultImgSuccess(result: resultImg!))
        } else {
            output.send(.getRecentCardResultImgFail)
        }
    }
}
