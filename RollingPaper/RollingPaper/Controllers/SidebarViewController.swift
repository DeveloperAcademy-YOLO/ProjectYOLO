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
        let photo = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        photo.layer.cornerRadius = photo.frame.width / 2
        photo.contentMode = UIView.ContentMode.scaleAspectFit
        return photo
    }()
    
    private let chevron: UIImageView = {
        let chevron = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        chevron.image = UIImage(systemName: "chevron.forward")
        chevron.contentMode = UIView.ContentMode.scaleAspectFit
        return chevron
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
        name.font = .boldSystemFont(ofSize: 20)
        name.sizeToFit()
        return name
    }()
    
    lazy var userInfoStack: UIStackView = {
        let userInfo = UIStackView(arrangedSubviews: [userPhoto, userName, chevron])
        userInfo.axis = .horizontal
        userInfo.spacing = 16
        return userInfo
    }()
    
    private let tableView: UITableView = {
        let tableview = UITableView()
        tableview.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.cellIdentifier)
        return tableview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = UIView()
        view.backgroundColor = .customSidebarBackgroundColor
        bind()
        setupSubviews()
        let tapUserInfo = UITapGestureRecognizer(target: self, action: #selector(didTapUserInfo(_: )))
        userInfoStack.addGestureRecognizer(tapUserInfo)
        tableView.separatorStyle = .none
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
        tableView.reloadData()
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
    
    @objc private func didTapUserInfo(_ sender: UITapGestureRecognizer) {
        print("UserInfoTapped!", sender)
    }
    
    private func setupSubviews() {
        setupProfileView()
        setupTableView()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        
        tableView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(128)
            make.trailing.bottom.equalToSuperview()
            make.top.equalTo(userInfoStack.snp.bottom).offset(40)
        }
    }
    
    private func setupProfileView() {
        view.addSubview(userInfoStack)
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
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func layout() {
        self.addSubview(categoryStack)
        categoryStack.isLayoutMarginsRelativeArrangement = true
        categoryStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 32, right: 0)
        
        categoryStack.snp.makeConstraints { make in
            make.leading.equalTo(self.snp.leading).offset(16)
            make.width.height.equalTo(24)
        }
    }
}
