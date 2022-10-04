//
//  SideMenuViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/04.
//

import UIKit

final class SideBarViewController: UIViewController {
    private var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private var sideMenuView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var screenWidth: CGFloat {
        view.frame.size.width
    }

    private var leadingConstraint: NSLayoutConstraint!
    private var shadowColor: UIColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 0.5)
    private var sideMenuItems: [SideBarItem] = []
    weak var delegate: SideBarDelegate?

    convenience init(sideMenuItems: [SideBarItem]) {
        self.init()
        self.sideMenuItems = sideMenuItems
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        view.backgroundColor = .clear
        view.frame.origin.x = -screenWidth

        addSubviews()
        configureTableView()
        configureTapGesture()
    }

    private func addSubviews() {
        view.addSubview(sideMenuView)
        sideMenuView.addSubview(headerView)
        sideMenuView.addSubview(tableView)
        configureConstraints()
    }

    private func configureConstraints() {
        sideMenuView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        leadingConstraint = sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -view.frame.size.width)
        leadingConstraint.isActive = true
        sideMenuView.widthAnchor.constraint(equalToConstant: view.frame.size.width * 0.25).isActive = true
        sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        headerView.topAnchor.constraint(equalTo: sideMenuView.topAnchor).isActive = true
        headerView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 150).isActive = true

        tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: sideMenuView.bottomAnchor).isActive = true
    }

    private func configureTableView() {
        tableView.backgroundColor = .white
        tableView.register(SideBarItemCell.self, forCellReuseIdentifier: SideBarItemCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.bounces = false
    }

    private func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func tapped() {
        hide()
    }

    func show() {
        self.view.frame.origin.x = 0
        self.view.backgroundColor = self.shadowColor
        UIView.animate(withDuration: 0.5) {
            self.leadingConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }

    func hide() {
        self.view.backgroundColor = .clear
        UIView.animate(withDuration: 0.5) {
            self.leadingConstraint.constant = -self.screenWidth
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.view.frame.origin.x = -self.screenWidth
        }
    }
}

extension SideBarViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else { return false }
        if view === headerView || view.isDescendant(of: tableView) {
            return false
        }
        return true
    }
}

extension SideBarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sideMenuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SideBarItemCell.identifier, for: indexPath) as? SideBarItemCell else {
            fatalError("Could not dequeue cell")
        }
        let item = sideMenuItems[indexPath.row]
        cell.configureCell(icon: item.icon, text: item.name)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let item = sideMenuItems[indexPath.row]
        delegate?.itemSelected(item: item.viewController)
    }
}

