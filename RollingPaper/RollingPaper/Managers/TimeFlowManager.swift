//
//  TimeFlowManager.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/14.
//

import Combine
import UIKit

// 타이머 시간 흐르게 하는 클래스
final class TimeFlowManager {
    private let timerInterval = 1.0 // 1초 간격
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    enum Input {
        case viewDidAppear
        case viewDidDisappear
    }
    enum Output {
        case timeIsUpdated
    }
    
    // 타이머 연동
    private func bindTimer() {
        timer = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else {return}
                // 타이머 업데이트 됐다고 알려주기
                self.output.send(.timeIsUpdated)
            })
    }
    
    // 뷰가 나타나면 타이머 연결, 사라지면 타이머 해제
    func transform(input: AnyPublisher<Input, Never>?) -> AnyPublisher<Output, Never> {
        guard let input = input else { return output.eraseToAnyPublisher()}
        input
            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .viewDidAppear:
                    self.bindTimer()
                case .viewDidDisappear:
                    self.timer?.cancel()
                }
            })
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
}
