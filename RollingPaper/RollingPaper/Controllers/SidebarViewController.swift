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
    private var cancellables = Set<AnyCancellable>()
    
    private let userPhoto: UIImageView = {
        let profilePhoto = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        profilePhoto.layer.cornerRadius = profilePhoto.frame.width / 2
        profilePhoto.contentMode = UIView.ContentMode.scaleAspectFit
        return profilePhoto
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
        name.font = .boldSystemFont(ofSize: 20)
        name.sizeToFit()
        return name
    }()
    
    lazy var userInfoStack: UIStackView = {
        let userInfo = UIStackView(arrangedSubviews: [userPhoto, userName])
        userInfo.axis = .horizontal
        userInfo.spacing = 16
        return userInfo
    }()
    
    private let tableView: UITableView = {
        let view = UITableView()
        view.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.cellIdentifier)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = UIView()
        self.view.backgroundColor = .customSidebarBackgroundColor
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    private func setupSubviews() {
        setupProfileView()
        setupTableView()
    }
    
    private func setupTableView() {
        self.view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(128)
            make.trailing.bottom.equalToSuperview()
            make.top.equalTo(userInfoStack.snp.bottom).offset(40)
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
        self.view.addSubview(userInfoStack)
        userInfoStack.backgroundColor = .white
        userInfoStack.layer.cornerRadius = 12
        userInfoStack.isLayoutMarginsRelativeArrangement = true
        userInfoStack.layoutMargins = UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16)
        
        userPhoto.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        
        userInfoStack.snp.makeConstraints { make in
            make.width.equalToSuperview().offset(-156)
            make.height.equalTo(74)
            make.leading.equalToSuperview().offset(128)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
        }
    }
}

class CategoryCell: UITableViewCell {
    
    static let cellIdentifier = "CategoryCell"
    
    let categoryIcon = UIImageView()
    let categoryName = UILabel()
    
    lazy var categoryStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [categoryIcon, categoryName])
        stack.axis = .horizontal
        stack.spacing = 16
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundConfiguration = .clear()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func layout() {
        self.addSubview(categoryStack)
        categoryStack.isLayoutMarginsRelativeArrangement = true
        categoryStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 32, right: 0)
        
        categoryStack.snp.makeConstraints { make in
            make.leading.equalTo(self.snp.leading).offset(16)
            make.width.height.equalTo(24)
        }
    }
}
