//
//  DateOfBirthViewController.swift
//  LKNWearable
//
//  Created by Andrew Sage on 30/09/2017.
//  Copyright © 2017 Andrew Sage Art & Entertainment Limited. All rights reserved.
//

import UIKit

class DateOfBirthViewController: UIViewController {

    var date = Date()
    
    @IBOutlet weak var datePicker: UIDatePicker!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.datePicker.date = self.date

        self.view.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(blurEffectView)
        self.view.sendSubview(toBack: blurEffectView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func okTapped(_ sender: Any) {
        self.date = datePicker.date
        performSegue(withIdentifier: "unwindWithDateSelected", sender: self)
    }
    
    @IBAction func todayTapped(_ sender: Any) {
        datePicker.setDate(Date(), animated: true)
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
