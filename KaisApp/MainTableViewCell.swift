//
//  MainViewTableViewCell.swift
//  KaisApp
//
//  Created by Elena on 10/31/17.
//  Copyright © 2017 Elena Caballero. All rights reserved.
//

import UIKit
import Cosmos
import FirebaseDatabase
import FirebaseStorage

class MainTableViewCell: UITableViewCell {

    //MARK: Main View outlets
    @IBOutlet weak var placesImage: UIImageView!
    @IBOutlet weak var placesName: UILabel!
    @IBOutlet weak var placesAddress: UILabel!
    @IBOutlet weak var cosmosView: CosmosView!
    
    //MARK: Images View outlets
    
    @IBOutlet weak var imagesImage: UIImageView!
    @IBOutlet weak var imagesAddress_Date: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var imagesUsername: UIButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if placesName != nil {
            placesName.text = ""
            placesImage.image = nil
            placesAddress.text = ""
        }
        
        if imagesAddress_Date != nil {
            imagesImage.image = nil
            imagesAddress_Date.text = ""
            likesLabel.text = ""
        }
    }
    
    @IBAction func likeButtonTouched(_ sender: Any) {
        if likeButton.currentImage == UIImage(named: "fullLike") {
            likeButton.setImage(UIImage(named: "emptyLike"), for: .normal)
        }else {
            likeButton.setImage(UIImage(named: "fullLike"), for: .normal)
        }
    }
    
    func mainPlaces(snap: DataSnapshot){
        var theImage: UIImage = UIImage()
        var theStars_Count: Int = Int()
        
        if let aPlace = snap.value as? Dictionary<String, AnyObject> {
            let city = snap.key.components(separatedBy: "-")
            placesName.text = city[0]
            if aPlace["address"] as? String != nil {
                placesAddress.text = (aPlace["address"] as? String)!
            }
            if let anImage = aPlace["img"] as? String {
                if let imageurl = URL(string: anImage) {
                    if let data = try? Data(contentsOf: imageurl){
                        theImage = UIImage(data: data)!
                        placesImage.image = theImage
                    }else {
                        theImage = UIImage(named: "error_image")!
                        placesImage.image = theImage
                    }
                }else {
                    theImage = UIImage(named: "error_image")!
                    placesImage.image = theImage
                }
            }else{
                theImage = UIImage(named: "error_image")!
                placesImage.image = theImage
            }
            if aPlace["stars_count"] as? Int != nil {
                theStars_Count = (aPlace["stars_count"] as? Int)!
                cosmosView.rating = Double(theStars_Count)
            }
        }
    }
    
    func imagesPlaces(snap: DataSnapshot, storage: StorageReference){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd,YYYY"
        likeButton.contentMode = .center
        likeButton.tintColor = UIColor.red
        likeButton.setImage(UIImage(named: "emptyLike"), for: .normal)
        
        var theImage: UIImage = UIImage()
        var theCity: String = String()
        var theUName: String = String()
        var theLikes: Int = Int()
        var theTime: NSDate = NSDate()
        
        if let anImageData = snap.value as? Dictionary<String, AnyObject> {
            let theImageURL = snap.key + ".jpg"
            let storageRef = storage.child(theImageURL)
            
            if anImageData["likes"] as? Int != nil {
                theLikes = (anImageData["likes"] as? Int)!
                self.likesLabel.text = ("\(String(theLikes))")
            }else{
                theLikes = 0;
                self.likesLabel.text = ("\(String(theLikes))")
            }
            if anImageData["uname"] as? String != nil {
                theUName = (anImageData["uname"] as? String)!
                self.imagesUsername.setTitle("   " + theUName, for: .normal)
            }
            if (anImageData["kaid"] as? String) != nil {
                if anImageData["timestamp"] as? TimeInterval != nil {
                    let t = anImageData["timestamp"] as? TimeInterval
                    theTime = NSDate(timeIntervalSince1970: t!/1000)
                }else {
                    theTime = NSDate()
                }
                theCity = (anImageData["kaid"] as? String)!
                self.imagesAddress_Date.text = "   " + theCity + " - " + String(dateFormatter.string(from: (theTime as Date)  ) )
            }
            
            storageRef.getData(maxSize: 1 * 1024 * 1024, completion: { (data, error) in
                if data != nil {
                    if UIImage(data: data!) == nil{
                        theImage = UIImage(named: "error_image")!
                        self.imagesImage.image = theImage
                    }else {
                        theImage = UIImage(data: data!)!
                        self.imagesImage.image = theImage
                    }
                }else {
                    theImage = UIImage(named: "error_image")!
                    self.imagesImage.image = theImage
                }
            })
            
        }
    }
    
    
}
