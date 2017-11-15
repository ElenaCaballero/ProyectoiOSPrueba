//
//  UserProfileTableViewController.swift
//  KaisApp
//
//  Created by Elena Caballero on 11/13/17.
//  Copyright © 2017 Elena Caballero. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseAuthUI
import GoogleSignIn
import FBSDKLoginKit
import FBSDKCoreKit

class UserProfileTableViewController: UITableViewController {
    
    var activityIndicatorView: UIActivityIndicatorView!
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    var picker:UIImagePickerController?=UIImagePickerController()
    
    var uid:String = String()
    var snapshots = [DataSnapshot]()
    var userSnapshot = [DataSnapshot]()
    var users = DataSnapshot()

    @IBOutlet var userProfileTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.color = UIColor.black
        
        userProfileTableView.backgroundView = activityIndicatorView
        
        self.hideKeyboardWhenTappedAround()
        
        userProfileTableView.register(UINib.init(nibName: "MainDetailHeader", bundle: Bundle.main), forHeaderFooterViewReuseIdentifier: "MainDetailHeaderID")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barTintColor = UIColor(rgb: 0x2390D4)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        tabBarController?.tabBar.barTintColor = UIColor(rgb: 0x2390D4)
        tabBarController?.tabBar.tintColor = UIColor(rgb: 0xff9510)
        
        if Auth.auth().currentUser != nil {
            uid = (Auth.auth().currentUser?.uid)!
            if let aUserData = users.value as? Dictionary<String, AnyObject> {
                let userName = aUserData["uname"] as? String
                self.navigationItem.title = userName
            }
        } else {
            self.navigationItem.title = "UserName"
        }
        
        if snapshots.isEmpty {
            activityIndicatorView.startAnimating()
            
            dispatchQueue.async {
                self.userProfileTableView.separatorStyle = .none
                
                Thread.sleep(forTimeInterval: 3)
                
                OperationQueue.main.addOperation() {
                    self.userProfileTableView.separatorStyle = .singleLine
                    
                    self.loadImageContentForCells()
                    self.loadUserContent()
                }
            }
            
        }
    }
    
    
    @IBAction func logOutAction(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "Authenticate")
                self.present(vc!, animated: true, completion: nil)
                
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } 
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            var countSnapshots = 0
            if snapshots.count > 0 {
                TableViewHelper.EmptyMessage(message: "", viewController: self)
                for snap in snapshots{
                    let thing = snap.value as? Dictionary<String, AnyObject>
                    let userID = thing!["uid"] as! String
                    if uid.caseInsensitiveCompare(userID) == ComparisonResult.orderedSame {
                        countSnapshots += 1
                    }
                }
                return countSnapshots
            }else {
                TableViewHelper.EmptyMessage(message: "Aún no hay fotografías,\n agrega una y muestra la magia de tus viajes.", viewController: self)
                return 0
            }
        default:
            assert(false, "section \(section)")
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 262
        }
        return 200
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 30
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = self.userProfileTableView.dequeueReusableHeaderFooterView(withIdentifier: "MainDetailHeaderID")
        if let mainDetailHeader = header as? MainDetailHeader{
            mainDetailHeader.setupSegmentedControlUserProfile()
        }
        return header
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userInfo", for: indexPath) as! UserProfileTableViewCell
            
            for user in userSnapshot {
                let userID = user.key
                print(userID)
                if uid.caseInsensitiveCompare(userID) == ComparisonResult.orderedSame {
                    users = user
                }
            }
            
            if userSnapshot.count > 0 {
                cell.forStaticCell(userId: uid, users: users, storageHero: storageHero, storageProfile: storageProfile)
            }else {
                cell.emptyStaticCell()
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "imagesArea", for: indexPath) as! UserProfileTableViewCell
        if indexPath.row >= snapshots.count {
            cell.backgroundColor = UIColor.black
        }else {
            cell.forDynamicCells(snapshot: snapshots[indexPath.row], storage: storage)
        }
        
        return cell
    }
    
    //MARK: - For opening gallery

    @IBAction func userProfileButtonTouched(_ sender: Any) {
        openGallery()
    }
    
    func openGallery(){
        picker!.allowsEditing = false
        picker!.sourceType = UIImagePickerControllerSourceType.photoLibrary
        present(picker!, animated: true, completion: nil)
    }
    
//    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true, completion: nil)
//    }
//
//    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
//            userProfileImageButton.contentMode = .scaleAspectFit
//            userProfileImageButton.setImage(pickedImage, for: .normal)
//        }
//        dismiss(animated: true, completion: nil)
//    }

    var ref: DatabaseReference!
    var storage: StorageReference!
    var storageHero: StorageReference!
    var storageProfile: StorageReference!
    
    func loadImageContentForCells(){
        ref = Database.database().reference(fromURL: "https://kaisapp-dev.firebaseio.com").child("images_data")
        storage = Storage.storage().reference(forURL: "gs://kaisapp-dev.appspot.com/images")
        
        ref.queryOrdered(byChild: "timestamp").observe(.value) { [weak self] (snapshot) in
            if let snapshots = snapshot.children.allObjects as? [DataSnapshot] {
                self?.snapshots = snapshots
                self?.activityIndicatorView.stopAnimating()
                self?.userProfileTableView.reloadSections(IndexSet.init(integer: 1), with: UITableViewRowAnimation.none)
            }
        }
    }
    
    func loadUserContent(){
        ref = Database.database().reference(fromURL: "https://kaisapp-dev.firebaseio.com").child("users")
        storageHero = Storage.storage().reference(forURL: "gs://kaisapp-dev.appspot.com/heros")
        storageProfile = Storage.storage().reference(forURL: "gs://kaisapp-dev.appspot.com/profiles")
        
        ref.queryOrderedByKey().observe(.value) { [weak self] (snapshot) in
            if let snapshots = snapshot.children.allObjects as? [DataSnapshot] {
                self?.userSnapshot = snapshots
                self?.activityIndicatorView.stopAnimating()
                self?.userProfileTableView.reloadSections(IndexSet.init(integer: 0), with: UITableViewRowAnimation.none)
            }
        }
    }
    
    //MARK: - Tabs Initializer
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem = UITabBarItem(title: "Perfil", image: UIImage(named: "user"), tag: 1)
    }

}

//MARK: - For dismissing keyboard

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
