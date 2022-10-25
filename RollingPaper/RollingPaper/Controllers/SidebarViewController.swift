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

private class Layout {
    static let userPhotoFrameWidthHeight = 44
    static let userNameFontSize: CGFloat = 20
    static let userPhotoToNamePadding: CGFloat = 16
    static let userChevronFrameWidth = Int(Double(userInfoStackWidthSuperView) * 0.3 * 0.24)
    static let userChevronWidthHeight = 15
    static let tableCellBackgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
    static let tableCellimageToTextPadding: CGFloat = 16
    static let tableCellInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    static let tableCellHeight: CGFloat = 56
    static let tableCellImageSize = CGSize(width: 25, height: 25)
    static let tableViewLeadingOffset = 128
    static let tableViewTrailingOffset = -28
    static let tableViewToUserInfoStackPadding = 24
    static let userInfoStackRadius: CGFloat = 12
    static let userInfoStackInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
    static let userInfoStackWidthSuperView = -156
    static let userInfoStackLeadingSuperView = 128
    static let userInfoStackTrailingSuperView = -28
    static let userInfoStackTopSafeArea = 40
}

class SidebarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var categories: [CategoryModel] = []
    private let viewModel = SidebarViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let userPhoto: UIImageView = {
        let photo = UIImageView()
        photo.image = UIImage(systemName: "person.circle")
        photo.layer.cornerRadius = photo.frame.width / 2
        photo.layer.masksToBounds = true
        photo.contentMode = UIView.ContentMode.scaleAspectFit
        return photo
    }()
    
    private let chevron: UIImageView = {
        let chevron = UIImageView()
        chevron.image = UIImage(systemName: "chevron.forward")
        chevron.contentMode = UIView.ContentMode.scaleAspectFit
        return chevron
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
        name.text = "요셉"
        name.font = UIFont.preferredFont(forTextStyle: .title3)
        name.sizeToFit()
        return name
    }()
    
    lazy var userInfoStack: UIStackView = {
        let userInfo = UIStackView(arrangedSubviews: [userPhoto, userName, chevron])
        userInfo.axis = .horizontal
        userInfo.alignment = .center
        userInfo.distribution = .fillProportionally
        userInfo.spacing = 0
        userInfo.setCustomSpacing(Layout.userPhotoToNamePadding, after: userPhoto)
        return userInfo
    }()
    
    private let tableView: UITableView = {
        let tableview = UITableView()
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        return tableview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        bind()
        setupSubviews()
        let tapUserInfo = UITapGestureRecognizer(target: self, action: #selector(didTapUserInfo(_: )))
        userInfoStack.addGestureRecognizer(tapUserInfo)
        tableView.separatorStyle = .none
    }
    
    private func bind() {
        viewModel
            .currentUserSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userModel in
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
        // 먼저 캐시를 체크, 로컬 스토리지 체크, 네트워크 다운로드! -> 다운로드받은 뒤에는 캐시에 일단 저장.
        // 로컬 스토리지에 URLString -> 프로필 다운로드 가능한지 체크
        // 다운로드 가능하면 캐시 매니저에 일단 저장, 해당 이미지 사용
        // 다운로드 불가능 -> 네트워크로 다운로드 -> 캐시 매니저에 저장
        FirebaseStorageManager
            .downloadData(urlString: urlString)
            .receive(on: DispatchQueue.global(qos: .background))
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
                    DispatchQueue.main.async {
                        self?.userPhoto.image = image
                    }
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
        var backgroundConfig = UIBackgroundConfiguration.listSidebarCell()
        backgroundConfig.backgroundInsets = Layout.tableCellBackgroundInsets
        cell.backgroundConfiguration = backgroundConfig
        cell.selectionStyle = .gray
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: category.icon)
        content.text = category.name
        content.textProperties.font = UIFont.preferredFont(forTextStyle: .title3)
        content.imageToTextPadding = Layout.tableCellimageToTextPadding
        content.imageProperties.tintColor = .systemGray3
        content.imageProperties.maximumSize = Layout.tableCellImageSize
        content.directionalLayoutMargins = Layout.tableCellInsets
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let category = self.categories[indexPath.row]
        NotificationCenter.default.post(
            name: Notification.Name.viewChangeFromSidebar,
            object: nil,
            userInfo: [NotificationViewKey.view: category.name])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.tableCellHeight
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
            make.leading.equalToSuperview().offset(Layout.tableViewLeadingOffset)
            make.trailing.equalToSuperview().offset(Layout.tableViewTrailingOffset)
            make.bottom.equalToSuperview()
            make.top.equalTo(userInfoStack.snp.bottom).offset(Layout.tableViewToUserInfoStackPadding)
        }
    }
    
    private func setupProfileView() {
        view.addSubview(userInfoStack)
        userInfoStack.backgroundColor = .systemBackground
        userInfoStack.layer.cornerRadius = Layout.userInfoStackRadius
        userInfoStack.isLayoutMarginsRelativeArrangement = true
        userInfoStack.layoutMargins = Layout.userInfoStackInset
        
        userInfoStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.userInfoStackLeadingSuperView)
            make.trailing.equalToSuperview().offset(Layout.userInfoStackTrailingSuperView)
            make.height.equalTo(userInfoStack.snp.width).dividedBy(3)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.userInfoStackTopSafeArea)
        }
        userPhoto.snp.makeConstraints { make in
            make.top.height.equalToSuperview().inset(14)
        }
        chevron.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(0.24)
        }
    }
}
