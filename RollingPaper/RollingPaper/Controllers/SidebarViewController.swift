//
//  SideBarViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/05.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa

protocol SidebarViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: CategoryModel)
}

class SidebarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: SidebarViewControllerDelegate?
    
    private var categories: [CategoryModel] = []
    private let viewModel = SidebarViewModel()
    
    private let userPhoto: UIImageView = {
        let profilePhoto = UIImageView()
        return profilePhoto
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
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
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = UIView()
        self.view.backgroundColor = .white
        bind()
        self.setupSubviews()
        self.tableView.separatorStyle = .none
        print("Load View")
    }
    
    private func bind() {
        viewModel
            .currentUserSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userModel in
                // self?.userPhoto.image = userModel.profileUrl
                if let userModel = userModel {
                    self?.convertURL(from: userModel.profileUrl)
                    self?.userName.text = userModel.name
                } else {
                    self?.userPhoto.image = UIImage(systemName: "person.circle")
                    self?.userName.text = "Guest"
                }
            }
            .store(in: &cancellables)
    }
    
    private func convertURL(from urlString: String?) {
        guard let urlString = urlString else { return}
        FirebaseStorageManager
            .downloadData(urlString: urlString)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error.localizedDescription)
                case .finished: break
                }
            } receiveValue: { [weak self] data in
                if
                    let data = data,
                    let image = UIImage(data: data) {
                    self?.userPhoto.image = image
                }
            }
            .store(in: &cancellables)

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
        self.setupProfileView()
    }
    
    private func setupTableView() {
        self.view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(300)
        }
        /*
        NSLayoutConstraint.activate([
            self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 300),
            self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
         */
    }
    
    private func setupProfileView() {
        self.view.addSubview(userName)
        self.view.addSubview(userPhoto)
        
        userName.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        userPhoto.snp.makeConstraints { make in
            make.leading.equalTo(userPhoto.snp.trailing).offset(10)
            make.top.equalTo(userPhoto.snp.top)
        }
        /*
        NSLayoutConstraint.activate([
            self.userPhoto.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 100),
            self.userPhoto.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200),
            self.userPhoto.bottomAnchor.constraint(equalTo: self.tableView.topAnchor),
            
            self.userName.leftAnchor.constraint(equalTo: userPhoto.rightAnchor, constant: 10),
            self.userName.topAnchor.constraint(equalTo: userPhoto.topAnchor),
            self.userName.bottomAnchor.constraint(equalTo: userPhoto.bottomAnchor)
        ])
         */
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
