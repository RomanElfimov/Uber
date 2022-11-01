//
//  SignUpController.swift
//  Uber
//
//  Created by Роман Елфимов on 14.08.2021.
//

import UIKit
import Firebase
import GeoFire

class SignUpController: UIViewController {
    
    // MARK: - Properties
    
    private var location = LocationHandler.shared.locationManager.location
    
    // Title label
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    // Email
    private lazy var emailContrainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)
    }()
    
    // Full name
    private lazy var fullNameContrainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x"), textField: fullNameTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let fullNameTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Имя", isSecureTextEntry: false)
    }()
    
    // Account Type
    private lazy var accountTypeContrainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_account_box_white_2x"), segmentedControl: segmentAccountTypeSegmentedControl)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return view
    }()
    
    private let segmentAccountTypeSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Пассажир", "Водитель"])
        sc.backgroundColor = .backgroundColor
        sc.tintColor = UIColor(white: 1, alpha: 0.87)
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    // Password
    private lazy var passwordContrainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Пароль", isSecureTextEntry: false)
    }()
    
    // signUp Button
    private lazy var signUpButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Зарегистрироваться", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()

    // alreadyHaveAccountButton
    lazy var alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Уже есть аккаунт?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Войти", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint]))
        
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
        configureUI()
    }
    
    // MARK: - Selectors
    @objc func handleSignUp() {
        
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let fullname = fullNameTextField.text else { return }
        let accountTypeIndex = segmentAccountTypeSegmentedControl.selectedSegmentIndex
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("DEBUG: Failed to register user with error: \(error)")
                return
            }
            
            guard let uid = result?.user.uid else { print("error in uid"); return }
            
            let values = ["email": email,
                          "fullname": fullname,
                          "accountType": accountTypeIndex] as [String: Any]
            
            // Driver's location while sign up
            if accountTypeIndex == 1 {
              
                let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
                
                guard let location = self?.location else {
                    let alertController = UIAlertController(title: "Локация не определена", message: "Измение настройки геолокации и попробуйте снова", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ок", style: .default, handler: nil)
                    alertController.addAction(action)
                    self?.present(alertController, animated: true, completion: nil)
                   
                    Auth.auth().currentUser?.delete()
                    return
                }
                
                geofire.setLocation(location, forKey: uid) { _ in
                    self?.uploadUserDataAndShowHomeController(uid: uid, values: values)
                }
            } else {
            // User's location while sign up
            self?.uploadUserDataAndShowHomeController(uid: uid, values: values)
            }
        }
    }
    
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helping functions
    
    func configureUI() {
        
        view.backgroundColor = .backgroundColor
        
        // title label
        view.addSubview(titleLabel)
        
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        
        // email & password stack view
        let stackView = UIStackView(arrangedSubviews: [emailContrainerView,
                                                       fullNameContrainerView,
                                                       passwordContrainerView,
                                                       accountTypeContrainerView,
                                                       signUpButton])
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 24
        
        view.addSubview(stackView)
        stackView.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
     
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
    }
    
    func uploadUserDataAndShowHomeController(uid: String, values: [String: Any]) {
        REF_USERS.child(uid).updateChildValues(values) { [weak self] _, _ in
            
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            
            guard let vc = keyWindow?.rootViewController as? ContainerController else { fatalError() }
            
            vc.configure()
            self?.dismiss(animated: true, completion: nil)
        
        }
    }
}
