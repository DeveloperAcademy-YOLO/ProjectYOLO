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
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
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
                print("SideBar Called!")
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
        let cell = UITableViewCell()
        let category = self.categories[indexPath.row]
        // TODO: 다음 스프린트 때 TableView를 Collection View로 Refactoring
        /*
        let backgroundCell: UIView = {
            var backgroundCell = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
            backgroundCell.backgroundColor = .gray
            return backgroundCell
        }()
        */
        var backgroundConfig = UIBackgroundConfiguration.listSidebarCell()
        backgroundConfig.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        // cell.selectedBackgroundView = backgroundCell
        cell.backgroundConfiguration = backgroundConfig
        cell.selectionStyle = .none
        
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: category.icon)
        content.text = category.name
        content.imageToTextPadding = 16
        content.imageProperties.tintColor = .systemGray3
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 0)
        cell.contentConfiguration = content
        
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
            make.trailing.equalToSuperview().offset(-28)
            make.bottom.equalToSuperview()
            make.top.equalTo(userInfoStack.snp.bottom).offset(24)
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
