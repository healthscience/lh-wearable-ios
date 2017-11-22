//
//  SettingsTableViewController.swift
//  LKNWearable
//
//  Created by Andrew Sage on 22/11/2017.
//  Copyright © 2017 Living Knowledge Network. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    var dob = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = UserDefaults.standard
        if let date = userDefaults.object(forKey: "dateOfBirth") as? Date {
            dob = date
        }
        
        let dateString = DateFormatter.localizedString(from: dob, dateStyle: .short, timeStyle: .none)
        
        self.dateOfBirthLabel.text = dateString
        
        if let value = userDefaults.object(forKey: "author") as? String {
            self.nameLabel.text = value
        } else {
            self.nameLabel.text = ""
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let controller = segue.destination as? DateOfBirthViewController {
            controller.date = self.dob
        }
    }

    
    @IBAction func unwindWithDateSelected(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? DateOfBirthViewController {
           
            self.dob = vc.date
            let userDefaults = UserDefaults.standard
            userDefaults.set(self.dob, forKey:"dateOfBirth")
            DispatchQueue.main.async {
                let dateString = DateFormatter.localizedString(from: self.dob, dateStyle: .short, timeStyle: .none)
                
                self.dateOfBirthLabel.text = dateString
            }
        }
    }
    
    @IBAction func unwindWithName(_ segue:UIStoryboardSegue) {
        if let nameController = segue.source as? NameTableViewController,
            let name = nameController.name {
            
            let userDefaults = UserDefaults.standard
            userDefaults.set(name, forKey:"author")
            self.nameLabel.text = name
        }
    }
}
