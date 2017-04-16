//
//  FirstViewController.swift
//  Places
//
//  Created by Karthi Ponnusamy on 1/4/17.
//  Copyright © 2017 Karthi Ponnusamy. All rights reserved.
//

import UIKit
import CoreLocation

class PlacesViewController: UIViewController {
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let loadingCell = "LoadingCell"
        static let autoCompleteCell = "AutoCompleteCell"
    }
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    var searchResults: [Place] = []
    var preditionList: [Prediction] = []
    var hasSearched = false
    var isLoading = false
    var filterDict = Dictionary<String, String>()
    var searchActive = false
    
    @IBOutlet weak var autoCompleteTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBarActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        autoCompleteTableView.dataSource = self
        autoCompleteTableView.delegate = self
        autoCompleteTableView.isHidden = true
        searchBarActivityIndicator.isHidden = true
        
        autoCompleteTableView.layer.shadowColor = UIColor.black.cgColor
        autoCompleteTableView.layer.shadowOpacity = 1
        autoCompleteTableView.layer.shadowOffset = CGSize.zero
        autoCompleteTableView.layer.shadowRadius = 10
        autoCompleteTableView.layer.shadowPath = UIBezierPath(rect: autoCompleteTableView.bounds).cgPath
        autoCompleteTableView.layer.shouldRasterize = true
        
//        autoCompleteTableView.clipsToBounds = false;
//        autoCompleteTableView.layer.masksToBounds = false
        autoCompleteTableView.alwaysBounceVertical = false
        
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        autoCompleteTableView.register(UITableViewCell.self, forCellReuseIdentifier: TableViewCellIdentifiers.autoCompleteCell)
        
        tableView.rowHeight = 100
        
        filterDict["type"] = Constants.SELECTED_TYPE
        filterDict["selectedRadius"] = Constants.SELECTED_RADIUS
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        getLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getLocation(){
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        updatingLocation = true
        print("getLocation2")
    }
    
    func showLocationServicesDeniedAlert() {
        var alertTitle = "Location Services Disabled"
        var alertMessage = "Please enable location services for this app in Settings."
        
        if let locationError = lastLocationError {
            alertTitle = "Error"
            alertMessage = "Unable to fetch current location."
        }
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default,
                                     handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func getSearchUrl(searchText: String) -> URL{
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let latitude = String(format: "%f", location!.coordinate.latitude)
        let longitude = String(format: "%f", location!.coordinate.longitude)
        //let radius = String(Float(filterDict["selectedRadius"]!)! * 1000)
        let radius = String(format: "%.0f", Float(filterDict["selectedRadius"]!)! * 1000)
        let types = filterDict["type"]
    
        let urlString = String(format:
            Constants.PLACES_SEARCH_URL, latitude, longitude, radius, types!, escapedSearchText, Constants.PLACES_API_KEY)
        
        let url = URL(string: urlString)
        print("url ==> \(url!)")
        return url!
    }
    
    func getAutoCompleteUrl(searchText: String) -> URL{
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let latitude = String(format: "%f", location!.coordinate.latitude)
        let longitude = String(format: "%f", location!.coordinate.longitude)
        let radius = String(format: "%.0f", Float(filterDict["selectedRadius"]!)! * 1000)
        
        let urlString = String(format:
            Constants.PLACES_AUTO_COMPLETE_URL, escapedSearchText, latitude, longitude, radius, Constants.PLACES_API_KEY)
        
        let url = URL(string: urlString)
        print("auto complete url ==> \(url!)")
        return url!
    }
    
    func parse(json data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
        } catch {
            print("JSON Error: \(error)")
            return nil
        }
    }
    
    
    func parseAutoComplete(dictionary: [String: Any]) -> [Prediction]{
        
        guard let status = dictionary["status"] as? String, status == "OK"  else {
            print("Invalid status")
            return []
        }
        
        guard let array = dictionary["predictions"] as? [Any], array.count > 0  else {
            print("Expected 'predictions' array or Array is empty")
            return []
        }
        
        var preditions: [Prediction] = []
        for resultDict in array {
            if let resultDict = resultDict as? [String : Any] {
                if let format = resultDict["structured_formatting"] as? [String : Any], let secondaryText = format["secondary_text"] as? String {
                    preditions.append(Prediction(prediction: secondaryText))
                    print("secondaryText => \(secondaryText)")
                }
            }
        }
        
        return preditions
    }
    
    
    func parse(dictionary: [String: Any]) -> [Place]{
        guard let status = dictionary["status"] as? String, status == "OK"  else {
            print("Invalid status")
            return []
        }
        
        guard let array = dictionary["results"] as? [Any], array.count > 0  else {
            print("Expected 'results' array or Array is empty")
            return []
        }
        
        var searchResults: [Place] = []
        for resultDict in array {
            
            var place:Place
            if let resultDict = resultDict as? [String : Any] {
                
                if let name = resultDict["name"] as? String, let place_id = resultDict["place_id"] as? String, let geometryDict = resultDict["geometry"] as? [String : Any] {
                    if let locationDict = geometryDict["location"] as? [String : Any] {
                        if let lat = locationDict["lat"] as? Double, let lng = locationDict["lng"] as? Double {

                            let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lng)

                            place = Place(name: name, place_id: place_id, locationCoordinate: coordinate)
                            
                            
                            if let rating = resultDict["rating"] as? Double {
                                place.rating = rating
                            }
                            
                            if let vicinity = resultDict["vicinity"] as? String {
                                place.vicinity = vicinity
                            }
                            
                            if let hoursDict = resultDict["opening_hours"] as? [String : Any] {
                                if let openNow = hoursDict["open_now"] as? Bool {
                                    place.open_now = openNow
                                    print("place.open_now \(place.open_now)")
                                }
                            }
                            
                            if let location = location {
                                let storeLocation: CLLocation =  CLLocation(latitude: lat, longitude: lng)
                                place.distance = calculateDistanceToStore(storeCoordinate: storeLocation)
                            }
                            
                            searchResults.append(place)
                        }
                    }
                }
            }
        }
        return searchResults
    }
    
    func showNetworkError() {
        let alert = UIAlertController(
            title: "Whoops...",
            message:
            "There was an error reading from the iTunes Store. Please try again.",
            preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func filterDidSelected(_ segue: UIStoryboardSegue)
    {
        let controller = segue.source as! FilterViewController
        filterDict = controller.filterDict
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenFilter" {
            let controller = segue.destination as! FilterViewController
            controller.filterDict = filterDict
        } else if segue.identifier == "ShowMap" {
            let controller = segue.destination as! MapViewController
            controller.places = searchResults
        } else if segue.identifier == "ShowDetail" {
            let controller = segue.destination as! PlaceDetailViewController
            let indexPath: IndexPath = sender as! IndexPath
            let place = searchResults[indexPath.item]
            controller.place = place
        }
    }
    
    func calculateDistanceToStore(storeCoordinate: CLLocation) -> Double? {
        if let location = location {
            let distanceInMeter = location.distance(from: storeCoordinate)
            let distanceinKiloMeter = distanceInMeter/1000
            print ("distance \(distanceinKiloMeter)")
            return distanceinKiloMeter
           //return "\(String(format:"%.1f", distanceinKiloMeter)) km"
            
            //return String(location.distance(from: storeCoordinate))
        } else {
            return nil
        }
    }
    

    
    func getPredictions(searchUrl: URL){
        
        let session = URLSession.shared
        
        //3
        let dataTask = session.dataTask(with: searchUrl, completionHandler: {
            data, response, error in
            // 4
            if let error = error {
                print("Failure! \(error)")
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200{
                if let data = data, let jsonDictionary = self.parse(json: data) {
                    self.preditionList = self.parseAutoComplete(dictionary: jsonDictionary)
                    print("self.searchResults \(self.searchResults)")
                    
                    DispatchQueue.main.async {
                        self.autoCompleteTableView.reloadData()
                        self.searchBarActivityIndicator.isHidden = true
                    }
                    return
                }
            } else {
                print("Fail! \(response!)")
            }
            
            DispatchQueue.main.async {
                self.autoCompleteTableView.reloadData()
                self.searchBarActivityIndicator.isHidden = true
            }
        })
        // 5
        dataTask.resume()
    }
}

extension PlacesViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        stopLocationManager()
        showLocationServicesDeniedAlert()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        location = newLocation
        stopLocationManager()
    }
}

extension PlacesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.autoCompleteTableView.isHidden = true;
        searchBar.resignFirstResponder()
        
        guard let location = location else {
            showLocationServicesDeniedAlert()
            return
        }
        
        isLoading = true
        tableView.reloadData()
        
        hasSearched = true
        searchResults = []
        
        
        let url = getSearchUrl(searchText: searchBar.text!)
        
        let session = URLSession.shared
        
        //3
        let dataTask = session.dataTask(with: url, completionHandler: {
            data, response, error in
            // 4
            if let error = error {
                print("Failure! \(error)")
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200{
                if let data = data, let jsonDictionary = self.parse(json: data) {
                    self.searchResults = self.parse(dictionary: jsonDictionary)
                    //self.searchResults.sort(by: <)
                    print("self.searchResults \(self.searchResults)")

                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.searchResults.sort(by: { Double($0.distance!) < Double($1.distance!) })
                        self.tableView.reloadData()
                    }
                    return
                }
            } else {
                print("Fail! \(response!)")
            }
            
            DispatchQueue.main.async {
                self.hasSearched = false
                self.isLoading = false
                self.tableView.reloadData()
                self.showNetworkError()
            }
        })
        // 5
        dataTask.resume()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        self.autoCompleteTableView.isHidden = true
        self.searchBarActivityIndicator.isHidden = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        print("searchText => \(searchText)")
        //self.tableView.reloadData()
        if searchText.characters.count >= 3 {
            let predctionUrl = self.getAutoCompleteUrl(searchText: searchText)
            self.autoCompleteTableView.isHidden = false
            self.searchBarActivityIndicator.startAnimating()
            self.searchBarActivityIndicator.isHidden = false
            self.getPredictions(searchUrl: predctionUrl)
        } else {
            self.autoCompleteTableView.isHidden = true
            self.searchBarActivityIndicator.isHidden = true
        }
    }
    
}

extension PlacesViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.autoCompleteTableView {
            //print("autoCompleteTableView >> numberOfRowsInSection")
            return self.preditionList.count
        }
        
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.autoCompleteTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.autoCompleteCell, for: indexPath)
            cell.textLabel?.text = self.preditionList[indexPath.row].prediction
            
            return cell
        }
        
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        }else if searchResults.count == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            cell.nameLabel.text = "(Nothing found)"
            cell.addressLabel.text = ""
            cell.distanceLabel.text = ""
            cell.openNowLabel.text = ""
            cell.starRatingView.isHidden = true
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            let searchResult:Place = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            cell.addressLabel.text = searchResult.vicinity
            if let rating = searchResult.rating {
                cell.starRatingView.rating = rating
            } else {
                cell.starRatingView.isHidden = true
            }
            
            /*
            let getLat: CLLocationDegrees = searchResult.coordinate.latitude
            let getLon: CLLocationDegrees = searchResult.coordinate.longitude
            let storeLocation: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
            cell.distanceLabel.text = calculateDistanceToStore(storeCoordinate: storeLocation)
             */
            if let distanceInKm = searchResult.distance {
                cell.distanceLabel.text = Util.formatDistanceText(distanceinKiloMeter: distanceInKm)
            }
            
            
            if let openNow = searchResult.open_now {
                if openNow {
                    cell.openNowLabel.text = "OPEN"
                    cell.openNowLabel.textColor = UIColor(hue: 0.2778, saturation: 0.93, brightness: 0.62, alpha: 1.0)
                } else {
                    cell.openNowLabel.text = "CLOSED"
                    cell.openNowLabel.textColor = UIColor.red
                }
            }

            
            return cell
        }
    }
}

extension PlacesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.autoCompleteTableView {
            if let prediction: Prediction = preditionList[indexPath.row] as Prediction{
                self.searchBar.text = prediction.prediction
                self.searchBar.delegate?.searchBarSearchButtonClicked!(self.searchBar)
                self.autoCompleteTableView.isHidden = true
            }
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        if searchResults.count > 0 {
            performSegue(withIdentifier: "ShowDetail", sender: indexPath)
        }
    }
}

