//
//  ContentViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/04.
//

import UIKit

class ContentViewController: UIViewController {
    weak var delegate: SideBarDelegate?
    var barButtonImage: UIImage? = UIImage(systemName: "sidebar.squares.left")

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        let barButtonItem = UIBarButtonItem(image: barButtonImage, style: .plain, target: self, action: #selector(menuTapped))
        barButtonItem.tintColor = .white
        navigationItem.setLeftBarButton(barButtonItem, animated: false)
    }

    @objc private func menuTapped() {
        delegate?.menuButtonTapped()
    }
}
