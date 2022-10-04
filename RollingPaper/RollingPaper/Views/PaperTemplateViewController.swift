//
//  HomeViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/04.
//
import UIKit

final class PaperTemplateViewController: ContentViewController {
    let myButton = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemTeal
        
        myButton.setTitle("This is Button", for: .normal)
        myButton.setTitleColor(.white, for: .normal)
        myButton.backgroundColor = .darkGray
        myButton.addTarget(self, action: #selector(btnClicked),for: .touchUpInside)
        self.view.addSubview(myButton)
        
        myButton.translatesAutoresizingMaskIntoConstraints = false
        myButton.centerXAnchor.constraint(equalTo:view.centerXAnchor).isActive = true
        myButton.centerYAnchor.constraint(equalTo:view.centerYAnchor).isActive = true
        myButton.heightAnchor.constraint(equalToConstant: 200).isActive = true
        myButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
    }
    
    @objc func btnClicked(){
       print("btnClicked")
    }
}
