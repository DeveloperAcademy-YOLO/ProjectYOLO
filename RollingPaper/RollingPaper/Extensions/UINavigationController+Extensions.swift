//
//  UINavigationController+Extensions.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/11.
//

import UIKit

// 네비게이션 애니메이션 끝나면 실행되게 하는 컴플리션
extension UINavigationController {
    
    private func doAfterAnimatingTransition(animated: Bool, completion: @escaping (() -> Void)) {
        if let coordinator = transitionCoordinator, animated {
            coordinator.animate(alongsideTransition: nil, completion: { _ in
                completion()
            })
        } else {
            completion()
        }
    }
    
    func pushViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping (() -> Void)) {
        pushViewController(viewController, animated: animated)
        doAfterAnimatingTransition(animated: animated, completion: completion)
    }
    
    func popViewController(_ animated: Bool, completion: @escaping (() -> Void)) {
        popViewController(animated: animated)
        doAfterAnimatingTransition(animated: animated, completion: completion)
    }
    
    func popToRootViewController(_ animated: Bool, completion: @escaping (() -> Void)) {
        popToRootViewController(animated: animated)
        doAfterAnimatingTransition(animated: animated, completion: completion)
    }
}
