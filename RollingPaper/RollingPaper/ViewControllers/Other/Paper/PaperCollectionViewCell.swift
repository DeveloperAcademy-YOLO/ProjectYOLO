//
//  PaperCollectionViewCell.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/12/02.
//

import UIKit
import Combine

class PaperCollectionViewCell: UICollectionViewCell {
    static let identifier = "PaperCollectionViewCell"
    private let cardImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.image = UIImage(named: "photo")
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cardImageView.frame = contentView.bounds
    }
    
    private func setUI() {
        contentView.addSubview(cardImageView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cardImageView.image = nil
    }
    
    func configure(with card: CardModel, paperSource: PaperViewModel.PaperSource) {
        switch paperSource {
        case .fromServer:
            if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
                cardImageView.image = image
            } else {
                guard let url = URL(string: card.contentURLString) else { return }
                var imageSubscription: AnyCancellable?
                imageSubscription = NetworkingManager.download(with: url)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] data in
                        guard let image = UIImage(data: data) else { return }
                        self?.cardImageView.image = image
                        NSCacheManager.shared.setImage(image: image, name: card.contentURLString)
                        imageSubscription?.cancel()
                    })
            }
        case .fromLocal:
            if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
                cardImageView.image = image
            } else {
                guard let image = LocalStorageManager.donwloadData(urlString: card.contentURLString) else { return }
                NSCacheManager.shared.setImage(image: image, name: card.contentURLString)
                cardImageView.image = image
            }
        }
    }
    
}
