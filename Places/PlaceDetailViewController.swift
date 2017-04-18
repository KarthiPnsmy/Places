//
//  PlaceDetailViewController.swift
//  Places
//
//  Created by Karthi Ponnusamy on 5/4/17.
//  Copyright © 2017 Karthi Ponnusamy. All rights reserved.
//

import UIKit
import ImageSlideshow
import Alamofire
import AlamofireImage
import Cosmos
import MapKit

class PlaceDetailViewController: UIViewController {

    @IBOutlet weak var imageSlideShow: ImageSlideshow!
    @IBOutlet weak var reviewTableView: UITableView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var phoneNoLabel: UILabel!
    @IBOutlet weak var awayLabel: UILabel!
    @IBOutlet weak var directionButton: UIButton!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var openNowLabel: UILabel!
    
    var place:Place?
    var isLoading = false
    var reviewList = [Review]()
    var blinkStatus = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reviewTableView.dataSource = self
        
        let cellNib = UINib(nibName: "ReviewCell", bundle: nil)
        reviewTableView.register(cellNib, forCellReuseIdentifier: "ReviewCell")
        
        reviewTableView.estimatedRowHeight = 140
        reviewTableView.rowHeight = UITableViewAutomaticDimension
   
        ratingView.settings.fillMode = .precise
        ratingView.settings.updateOnTouch = false
        
        if let place = place {
            self.navigationItem.title = place.name
            self.addressLabel.text = place.vicinity
            
            if let rating = place.rating {
                ratingView.rating = rating
            } else {
                ratingView.isHidden = true
            }
            
            if let openNow = place.open_now {
                if openNow {
                    openNowLabel.text = "OPEN"
                    openNowLabel.textColor = UIColor(hue: 0.2778, saturation: 0.93, brightness: 0.62, alpha: 1.0)
                } else {
                    openNowLabel.text = "CLOSED"
                    openNowLabel.textColor = UIColor.red
                }
                
                let timer = Timer(timeInterval: 1.5, target: self, selector: #selector(PlaceDetailViewController.blink), userInfo: nil, repeats: true)
                RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
            } else {
                openNowLabel.isHidden = true
            }

            
            if let distanceInKm = place.distance {
                awayLabel.text = "\(Util.formatDistanceText(distanceinKiloMeter: distanceInKm)) away"
            }
            
            isLoading = true
            getPlaceDetail()
        }
        
        imageSlideShow.backgroundColor = UIColor.white
        imageSlideShow.slideshowInterval = 5.0
        imageSlideShow.pageControlPosition = PageControlPosition.insideScrollView
        imageSlideShow.pageControl.currentPageIndicatorTintColor = UIColor.lightGray
        imageSlideShow.pageControl.pageIndicatorTintColor = UIColor.gray
        imageSlideShow.contentScaleMode = UIViewContentMode.scaleAspectFill
        imageSlideShow.currentPageChanged = { page in
            print("current page:", page)
        }
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(PlaceDetailViewController.didTap))
        imageSlideShow.addGestureRecognizer(recognizer)
        
        
        let phoneTap = UITapGestureRecognizer(target: self, action: #selector(PlaceDetailViewController.phoneNoTapped))
        phoneNoLabel.isUserInteractionEnabled = true
        phoneNoLabel.addGestureRecognizer(phoneTap)
    }
    
    func blink(){
        openNowLabel.alpha = 0.0
        UILabel.animate(withDuration: 1.5, animations: {
            self.openNowLabel.alpha = 1.0
        }, completion: {
            (value: Bool) in
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reviewTableView.reloadData()
        print("table height1 -> \(self.reviewTableView.frame.height)")
    }
    
    
    func didTap() {
        imageSlideShow.presentFullScreenController(from: self)
    }

    func phoneNoTapped(sender:UITapGestureRecognizer) {
        print("phoneNoTapped working")
        callNumber(phoneNumber: phoneNoLabel.text!)
    }
    
    private func callNumber(phoneNumber:String) {
        print(phoneNumber)
        if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            } else {
                print("phoneCallURL canOpenURL nil")
            }
        } else {
            print("phoneCallURL is nil")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func directToPlace(_ sender: UIButton) {
        if let coordinate = place?.coordinate {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            mapItem.name = place?.name
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    func tapFunction(sender:UITapGestureRecognizer) {
        print("tap working")
    }
    
    
    
    func loadPlaceImages(){
        var remoteImageSource = [AlamofireSource] ()
        let defaultImage = UIImage(named:"placeholder_image")

        if let photos = place?.photos {
            for photo in photos {
                let photoUrlString = String(format: Constants.PLACES_PHOTO_URL, photo, Constants.PLACES_API_KEY)
                print("photoUrlString \(photoUrlString)")
                //let url = URL(string: urlString)
                let source = AlamofireSource(urlString: photoUrlString, placeholder: defaultImage)!
                remoteImageSource.append(source)
            }
            imageSlideShow.setImageInputs(remoteImageSource)
        }
    }

    func parse(json data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
        } catch {
            print("JSON Error: \(error)")
            return nil
        }
    }
    
    func parse(dictionary: [String: Any]) {
        print("parse(dictionary")
        
        guard let status = dictionary["status"] as? String, status == "OK"  else {
            print("Invalid status >> \(dictionary["status"]! as? String)")
            return
        }
        
        
        guard let resultDict = dictionary["result"] as? [String : Any] else {
            print("Expected 'result' as dict")
            return
        }
        

        if let phoneNo = resultDict["international_phone_number"] as? String {
            place!.phone_number = phoneNo
            //print("place!.phone_number \(place!.phone_number)")
        }
        
        if let openingHoursDict = resultDict["opening_hours"] as? [String : Any]{
            if let openingHoursArr = openingHoursDict["weekday_text"] as? [String] {
                place!.timings = openingHoursArr
                //print("place!.timings \(place!.timings)")
            }
        }
        
        var photosList = [String]()
        if let photosArray = resultDict["photos"] as? [Any]{
            for photoDict in photosArray {
                if let photoDict = photoDict as? [String : Any] {
                    if let photoReference = photoDict["photo_reference"] {
                        photosList.append(photoReference as! String)
                    }
                }
            }
        }
        place?.photos = photosList
        //print("photoReference \(photosList)")
        
        

        if let reviewArray = resultDict["reviews"] as? [Any]{
            for reviewDict in reviewArray {
                if let reviewDict = reviewDict as? [String : Any] {
                    if let author_name = reviewDict["author_name"],
                        let profile_photo_url = reviewDict["profile_photo_url"],
                        let rating = reviewDict["rating"] as? Float,
                        let relative_time_description = reviewDict["relative_time_description"],
                        let text = reviewDict["text"]{
                        
                        let review = Review(username: author_name as! String, review_text: text as! String, review_time: relative_time_description as! String, user_profile_image: profile_photo_url as! String, rating: rating)
//                        print("author_name \(author_name) ")
//                        print("profile_photo_url \(profile_photo_url) ")
//                        print("rating \(rating) ")
//                        print("relative_time_description \(relative_time_description) ")
//                        print("text \(text) ")
                        reviewList.append(review)
                    }
                }
            }
        }
        place?.reviews = reviewList
    }
    
    func getPlaceDetail(){
        let url = getSearchUrl()
        let session = URLSession.shared
        
        //3
        let dataTask = session.dataTask(with: url, completionHandler: {
            data, response, error in
            // 4
            if let error = error {
                print("Failure! \(error)")
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200{
                if let data = data, let jsonDictionary = self.parse(json: data) {
                    
                    print("data jsonDictionary")
                    self.parse(dictionary: jsonDictionary)
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.loadPlaceImages()
                        self.reviewTableView.reloadData()
                        self.phoneNoLabel.text = self.place?.phone_number
                        //self.reviewTableView.frame.size.height = CGFloat(120 * self.reviewList.count)
                    }
                    return
                }
                //print("data \(data)")
            } else {
                print("Fail! \(response!)")
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                //self.showNetworkError()
            }
        })
        // 5
        dataTask.resume()
    }

    func getSearchUrl() -> URL{
        let urlString = String(format: Constants.PLACES_DETAIL_URL, place!.place_id, Constants.PLACES_API_KEY)
        
        let url = URL(string: urlString)
        print("detail url ==> \(url!)")
        return url!
    }
}

extension PlaceDetailViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return reviewList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReviewCell", for: indexPath) as! ReviewCell
        let review:Review = reviewList[indexPath.row]
        cell.nameLabel.text = review.username
        cell.reviewLabel.numberOfLines = 0
        cell.reviewLabel.text = review.review_text
        cell.starRatingView.rating = Double(review.rating)
        let defaultImage = UIImage(named:"placeholder_image")
        cell.profileImage.af_setImage(withURL: URL(string: review.user_profile_image)!, placeholderImage: defaultImage)
        cell.reviewDateLabel.text = review.review_time
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Reviews"
    }
}
