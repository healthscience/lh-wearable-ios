//
//  NameTableViewController.swift
//  LKNWearable
//
//  Created by Andrew Sage on 22/08/2016.
//  Copyright © 2017 Andrew Sage Art & Entertainment Limited. All rights reserved.
//

import UIKit

class NameTableViewController: UITableViewController {
    
    var name: String!

    @IBOutlet weak var nameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.nameTextField.text = name
        
        self.title = "Name"
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isMovingFromParentViewController){
            name = self.nameTextField.text
            performSegue(withIdentifier: "unwindWithName", sender: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
