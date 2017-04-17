//
//  FilterViewController.swift
//  Places
//
//  Created by Karthi Ponnusamy on 2/4/17.
//  Copyright © 2017 Karthi Ponnusamy. All rights reserved.
//

import UIKit
import DLRadioButton
class FilterViewController: UIViewController {

    @IBOutlet var atmBtn: DLRadioButton!;
    @IBOutlet var bankBtn: DLRadioButton!;
    @IBOutlet var bar: DLRadioButton!
    @IBOutlet var cafeBtn: DLRadioButton!
    @IBOutlet var doctorBtn: DLRadioButton!
    @IBOutlet var hospitalBtn: DLRadioButton!
    @IBOutlet var parkBtn: DLRadioButton!
    @IBOutlet var slider: UISlider!
    
    @IBOutlet weak var selectedRadiusLabel: UILabel!
    var selectedType = Constants.SELECTED_TYPE;
    var selectedRadius = Constants.SELECTED_RADIUS
    var filterDict = Dictionary<String, String>()
    
    @IBOutlet weak var restaurant: DLRadioButton!
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        selectedRadius = String(format:"%.1f",(sender.value))
        selectedRadiusLabel.text = "(\(selectedRadius) km)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let wrapperType = filterDict["type"] {
            switch wrapperType {
            case "atm":
                atmBtn.isSelected = true
            case "bank":
                bankBtn.isSelected = true
            case "bar":
                bar.isSelected = true
            case "cafe":
                cafeBtn.isSelected = true
            case "doctor":
                doctorBtn.isSelected = true
            case "hospital":
                hospitalBtn.isSelected = true
            case "park":
                parkBtn.isSelected = true
            case "restaurant":
                restaurant.isSelected = true
            default:
                break
            }
        }
        
        slider.setValue(Float(filterDict["selectedRadius"]!)!, animated: true)
        selectedRadiusLabel.text = "(\(filterDict["selectedRadius"]!) km)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func apply(_ sender: Any) {
        selectedType = (atmBtn.selected()?.titleLabel?.text)!
        
        filterDict["type"] = selectedType
        filterDict["selectedRadius"] = selectedRadius
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FilterDidSelected" {
            selectedType = (atmBtn.selected()?.titleLabel?.text)!
            filterDict["type"] = selectedType
            filterDict["selectedRadius"] = selectedRadius
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
