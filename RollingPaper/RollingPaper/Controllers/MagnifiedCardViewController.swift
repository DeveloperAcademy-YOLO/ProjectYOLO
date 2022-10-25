//
//  MagnifiedCardViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/26.
//

import Foundation
import UIKit

class MagnifiedCardViewController: UIViewController {
    var cardContentURLString: String?
    var magnifiedCardImage = UIImageView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImageSize()
        showImage()
    }
    
    func setImageSize() {
        magnifiedCardImage.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalTo(200)
        }
    } //확대된 카드의 사이즈 결정
    
    func showImage() {
        guard let contentURLString = cardContentURLString else {return}
        if let image = NSCacheManager.shared.getImage(name: contentURLString) {
            magnifiedCardImage.image = image
        }
        else {
            LocalStorageManager.downloadData(urlString: contentURLString)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error): print(error)
                    case .finished: break
                    }
                } receiveValue: { [weak self] data in
                    if
                        let data = data,
                        let image = UIImage(data: data) {
                        NSCacheManager.shared.setImage(image: image, name: contentURLString)
                        self?.magnifiedCardImage.image = image
                    } else {
                        self?.magnifiedCardImage.image = UIImage(systemName: "person.circle")
                    }
                }
        }
    } // 선택된 카드를 불러오는 로직
    
}
