//
//  SideBarViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/05.
//

import UIKit
import SnapKit

protocol SidebarViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: CategoryModel)
}

class SidebarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: SidebarViewControllerDelegate?
    
    private var categories: [CategoryModel] = []
    
    private let userPhoto: UIImageView = {
        let profilePhoto = UIImageView()
        profilePhoto.translatesAutoresizingMaskIntoConstraints = false
        profilePhoto.image = UIImage(systemName: "doc.on.doc")
        return profilePhoto
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
        name.translatesAutoresizingMaskIntoConstraints = false
        name.text = "바트 심슨"
        name.font = .boldSystemFont(ofSize: 20)
        name.sizeToFit()
        return name
    }()
    
    private let tableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.cellIdentifier)
        return view
    }()
    
    override func loadView() { // TODO: viewDidLoad, loadView 둘중 무엇을 쓸것인지
        self.view = UIView()
        self.view.backgroundColor = .white
        self.setupSubviews()
        self.tableView.separatorStyle = .none
    }
    
    func show(categories: [CategoryModel]) {
        self.categories = categories
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = self.categories[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.cellIdentifier, for: indexPath) as? CategoryCell else { fatalError("Table Cell Error") }
        var content = cell.defaultContentConfiguration()
        
        content.text = category.name
        content.image = UIImage(systemName: category.icon)
        cell.contentConfiguration = content
        cell.selectionStyle = .gray
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let category = self.categories[indexPath.row]
        self.delegate?.didSelectCategory(category)
    }
    
    private func setupSubviews() {
        self.setupTableView()
    }
    
    private func setupTableView() {
        self.view.addSubview(tableView)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        NSLayoutConstraint.activate([
            self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200),
            self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    private func setupProfileView() { // TODO: 회원 프로필 뷰
        self.view.addSubview(userName)
        self.view.addSubview(userPhoto)
        
        NSLayoutConstraint.activate([
            self.userPhoto.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 100),
            self.userPhoto.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200),
            self.userPhoto.bottomAnchor.constraint(equalTo: self.tableView.topAnchor),
            self.userPhoto.leadingAnchor.constraint(equalTo: self.view.rightAnchor),
            
            self.userName.leftAnchor.constraint(equalTo: userPhoto.rightAnchor, constant: 50),
            self.userName.topAnchor.constraint(equalTo: userPhoto.topAnchor),
            self.userName.bottomAnchor.constraint(equalTo: userPhoto.bottomAnchor),
            self.userName.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
    }
}

class CategoryCell: UITableViewCell {
    
    static let cellIdentifier = "CategoryCell"
    
    let categoryIcon = UIImageView()
    let categoryName = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
     }
    
    func layout() {
        self.addSubview(categoryIcon)
        self.addSubview(categoryName)
        
        categoryIcon.translatesAutoresizingMaskIntoConstraints = false
        categoryName.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            categoryIcon.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            categoryIcon.widthAnchor.constraint(equalToConstant: 20),
            categoryIcon.heightAnchor.constraint(equalToConstant: 20),
            categoryName.leadingAnchor.constraint(equalTo: categoryIcon.trailingAnchor, constant: 10)
        ])
    }
}
