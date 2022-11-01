//
//  SettingsController.swift
//  Uber
//
//  Created by Роман Елфимов on 26.08.2021.
//

import UIKit

// MARK: - Reuse Id

private let reuseIdentifier = "LocationCell"

protocol SettingsControllerDelegate: AnyObject {
    func updateUser(_ controller: SettingsController)
}

// MARK: - Location Type Enum

enum LocationType: Int, CaseIterable, CustomStringConvertible {
    case home
    case work
    
    var description: String {
        switch self {
        case .home:
            return "Добавить домашний адрес"
        case .work:
            return "Добавить рабочий адрес"
        }
    }
    
    var subtitle: String {
        switch self {
        case .home:
            return "Add Home"
        case .work:
            return "Add Work"
        }
    }
}

// MARK: - Controller

class SettingsController: UITableViewController {
    
    // MARK: - Properties
    
    var user: User
    private let locationManager = LocationHandler.shared.locationManager
    weak var delegate: SettingsControllerDelegate?
    var userInfoUpdated = false
    
    // Menu Header
    private lazy var infoHeader: UserInfoHeader = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 100)
        let view = UserInfoHeader(user: user, frame: frame)
        return view
    }()
    
    // MARK: - Lifecycle
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        configureTableView()
        configureNavigationBar()
    }
    
    // MARK: - Helper Functions
    
    func locationText(forType type: LocationType) -> String {
        switch type {
        case .home:
            return user.homeLocation ?? type.subtitle
        case .work:
            return user.workLocation ?? type.subtitle
        }
    }
    
    func configureTableView() {
        tableView.rowHeight = 60
        
        // Переиспользуем ячейки из LocationCell
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.backgroundColor = .white
        tableView.tableHeaderView = infoHeader
        tableView.tableFooterView = UIView()
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        navigationItem.title = "Настройки"
        navigationController?.navigationBar.barTintColor = .backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismissal))
    }
    
    // MARK: - Selectors
    
    @objc func handleDismissal() {
    
        if userInfoUpdated {
            delegate?.updateUser(self)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TableView Delegate/DataSource
 
extension SettingsController {
         
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocationType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? LocationCell else { return UITableViewCell() }
        
        guard let type = LocationType(rawValue: indexPath.row) else { return cell }
        
        cell.titleLabel.text = type.description
        cell.addressLabel.text = locationText(forType: type)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16)
        title.textColor = .white
        title.text = "Избранное"
        view.addSubview(title)
        title.centerY(inView: view, leftAnchor: view.leftAnchor, paddingLeft: 16)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let type = LocationType(rawValue: indexPath.row) else { return }
       
        guard let location = locationManager?.location else { return }
        let controller = AddLocationController(type: type, location: location)
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }
}

// MARK: - Add LocationController Delegate

extension SettingsController: AddLocationControllerDelegate {
    func updateLocation(locationString: String, type: LocationType) {
        PassengerService.shared.saveLocation(locationString: locationString, type: type) { [weak self] _, _ in
            self?.dismiss(animated: true, completion: nil)
            self?.userInfoUpdated = true
            
            switch type {
            case .home:
                self?.user.homeLocation = locationString
            case .work:
                self?.user.workLocation = locationString
            }
            
            self?.tableView.reloadData()
        }
    }
}
