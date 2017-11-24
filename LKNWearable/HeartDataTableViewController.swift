//
//  HeartDataTableViewController.swift
//  LKNWearable
//
//  Created by Andrew Sage on 06/11/2017.
//  Copyright © 2017 Living Knowledge Network. All rights reserved.
//

import UIKit
import CoreData

class HeartDataTableViewController: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var heartData = [NSManagedObject]()
    var heartRateZones = [ClosedRange<Int>]()
    var zoneBackgroundColours = [UIColor]()
    var zoneTextColours = [UIColor]()
    
    var currentDate = Date()
    var baseDate = Date()

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        
        self.title = formatter.string(from: currentDate)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        layout.itemSize = CGSize(width: width / 8, height: width / 8)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadData() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HeartRate")
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        let sortDescriptors = [sort]
        fetchRequest.sortDescriptors = sortDescriptors
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: currentDate)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)
        
        
        let predicate = NSPredicate(format: "(timestamp >= %@) AND (timestamp < %@) AND bpm > 0", startDate as CVarArg, endDate! as CVarArg);
        
        fetchRequest.predicate = predicate
        
        do {
            heartData = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return heartData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reading", for: indexPath)
        
        let heartRate = heartData[indexPath.row]
        
        var bpm = 0
        if let value = heartRate.value(forKey: "bpm") as? Int {
            bpm = value
        }
        
        var date = Date()
        if let value = heartRate.value(forKey: "timestamp") as? Date {
            date = value
        }
        
        var status = 0
        if let value = heartRate.value(forKey: "status") as? Int {
            status = value
        }
        
        var currentZone = 0
        for zone in 0...5 {
            let zoneRange = heartRateZones[zone]
            if zoneRange.contains(bpm) {
                currentZone = zone
                break
            }
        }
        
        // initialize the date formatter and set the style
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        
        let timeLabel = cell.viewWithTag(1) as! UILabel
        let bpmLabel = cell.viewWithTag(2) as! UILabel
        let zoneLabel = cell.viewWithTag(3) as! UILabel
        timeLabel.text = formatter.string(from: date)
        
        switch status {
        case 0: // unsent
            timeLabel.textColor = .red
            
        case 1: // queued for batch sending
            timeLabel.textColor = .orange
            
        case 2: // sent
            timeLabel.textColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1.0)
        
        default:
            timeLabel.textColor = .blue
        }
        
        bpmLabel.text = "\(bpm)"
        zoneLabel.text = "\(currentZone)"
        zoneLabel.clipsToBounds = true
        zoneLabel.layer.cornerRadius = 10

        zoneLabel.backgroundColor = self.zoneBackgroundColours[currentZone]
        zoneLabel.textColor = self.zoneTextColours[currentZone]
        
        return cell
    }

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "day", for: indexPath)
        
        let today = baseDate
        let date = Calendar.current.date(byAdding: .day, value: -(6 - indexPath.row), to: today)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEEEE")
        
        let dayLabel = cell.viewWithTag(2) as! UILabel
        dayLabel.text = dateFormatter.string(from: date)
        
        dateFormatter.setLocalizedDateFormatFromTemplate("d/MM")
        let dateLabel = cell.viewWithTag(1) as! UILabel
        dateLabel.text = dateFormatter.string(from: date)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let today = baseDate
        currentDate = Calendar.current.date(byAdding: .day, value: -(6 - indexPath.row), to: today)!
        
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        
        self.title = formatter.string(from: currentDate)
        
        self.reloadData()
    }
    
    @IBAction func swipeGestureRecongized(_ sender: Any) {
        baseDate = Calendar.current.date(byAdding: .day, value: -7, to: baseDate)!
        currentDate = baseDate
        
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        
        self.title = formatter.string(from: currentDate)
        
        self.collectionView.reloadData()
        self.reloadData()
    }
    
    @IBAction func swipeLeftGestureRecongized(_ sender: Any) {
        baseDate = Calendar.current.date(byAdding: .day, value: 7, to: baseDate)!
        currentDate = baseDate
        
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        
        self.title = formatter.string(from: currentDate)
        
        self.collectionView.reloadData()
        self.reloadData()
    }
    
    @IBAction func todayTapped(_ sender: Any) {
        baseDate = Date()
        currentDate = baseDate
        
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        
        self.title = formatter.string(from: currentDate)
        
        self.collectionView.reloadData()
        self.reloadData()
    }
}
