//
//  ViewController.swift
//  LKNWearable
//
//  Created by Andrew Sage on 05/07/2017.
//  Copyright © 2017 Living Knowledge Network. All rights reserved.
//

import UIKit
import CoreBluetooth
import Alamofire
import CoreData

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var manufacturerLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var batteryLevelLabel: UILabel!
    
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var heartView: UIView!
    @IBOutlet weak var heartInsideView: UIView!
    @IBOutlet weak var zone0Label: UILabel!
    @IBOutlet weak var zone1Label: UILabel!
    @IBOutlet weak var zone2Label: UILabel!
    @IBOutlet weak var zone3Label: UILabel!
    @IBOutlet weak var zone4Label: UILabel!
    @IBOutlet weak var zone5Label: UILabel!
    @IBOutlet weak var currentZoneLabel: UILabel!
    @IBOutlet weak var sessionMaxLabel: UILabel!
    
    // BLE stuff
    var centralManager: CBCentralManager? = nil
    var heartMonitorPeripheral: CBPeripheral? = nil
    var lostPeripheral: CBPeripheral? = nil // device previously connected to when disconnected
    
    // Heart Rate Zones
    var restingHeartRate = 63
    var age = 44
    var heartRateReserve = 0
    
    var zoneColours = [UIColor.magenta, UIColor.blue, UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red]
    var zoneTextColours = [UIColor.white, UIColor.white, UIColor.black, UIColor.black, UIColor.white, UIColor.white]
    
    // Standard service and characterstic UUIDs as defined at
    // https://www.bluetooth.com/specifications/gatt/services

    let HEART_RATE_SERVICE_UUID = "180D"
    let DEVICE_INFO_SERVICE_UUID = "180A"
    let BATTERY_SERVICE_UUID = "180F"
    
    let MANUFACTURER_NAME_CHARACTERSTIC_UUID = "2A29"
    let HEART_RATE_MEASUREMENT_CHARACTERSTIC_UUID = "2A37"
    let BODY_LOCATION_CHARACTERSTIC_UUID = "2A38"
    
    let BATTERY_LEVEL_CHARACTERSTIC_UUID = "2A19"
    
    var deviceName = ""
    var location = ""
    var locationID = 0
    
    var heartRateZones = [ClosedRange<Int>]()
    var currentZone = 0
    
    var sessionMax = 0
    
    var heartData = [NSManagedObject]()
    
    var hasLostConnection = false
    
    // Server stuff
    var serverToken = ""
    var author = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.heartView.layer.cornerRadius = 100
        self.heartView.clipsToBounds = true
        
        self.heartInsideView.layer.cornerRadius = 75
        self.heartInsideView.clipsToBounds = true
        
        self.sessionMaxLabel.text = "\(sessionMax)"
        
        let maxHeartRate = 220 - age
        heartRateReserve = maxHeartRate - restingHeartRate
        
        heartRateZones.append((Int(Double(heartRateReserve) * 0.0) + restingHeartRate)...(Int(Double(heartRateReserve) * 0.5) + restingHeartRate))
        heartRateZones.append((Int(Double(heartRateReserve) * 0.5) + restingHeartRate)...(Int(Double(heartRateReserve) * 0.6) + restingHeartRate))
        heartRateZones.append((Int(Double(heartRateReserve) * 0.6) + restingHeartRate)...(Int(Double(heartRateReserve) * 0.7) + restingHeartRate))
        heartRateZones.append((Int(Double(heartRateReserve) * 0.7) + restingHeartRate)...(Int(Double(heartRateReserve) * 0.8) + restingHeartRate))
        heartRateZones.append((Int(Double(heartRateReserve) * 0.8) + restingHeartRate)...(Int(Double(heartRateReserve) * 0.9) + restingHeartRate))
        heartRateZones.append((Int(Double(heartRateReserve) * 0.9) + restingHeartRate)...(Int(Double(heartRateReserve) * 1.0) + restingHeartRate))

        zone0Label.text = "Zone 0 : less than \(heartRateZones[1].lowerBound)"
        zone1Label.text = "Zone 1 : \(heartRateZones[1].lowerBound) - \(heartRateZones[1].upperBound)"
        zone2Label.text = "Zone 2 : \(heartRateZones[2].lowerBound) - \(heartRateZones[2].upperBound)"
        zone3Label.text = "Zone 3 : \(heartRateZones[3].lowerBound) - \(heartRateZones[3].upperBound)"
        zone4Label.text = "Zone 4 : \(heartRateZones[4].lowerBound) - \(heartRateZones[4].upperBound)"
        zone5Label.text = "Zone 5 : \(heartRateZones[5].lowerBound) - \(heartRateZones[5].upperBound)"
        
        zone0Label.backgroundColor = zoneColours[0]
        zone1Label.backgroundColor = zoneColours[1]
        zone2Label.backgroundColor = zoneColours[2]
        zone3Label.backgroundColor = zoneColours[3]
        zone4Label.backgroundColor = zoneColours[4]
        zone5Label.backgroundColor = zoneColours[5]
        
        zone0Label.textColor = zoneTextColours[0]
        zone1Label.textColor = zoneTextColours[1]
        zone2Label.textColor = zoneTextColours[2]
        zone3Label.textColor = zoneTextColours[3]
        zone4Label.textColor = zoneTextColours[4]
        zone5Label.textColor = zoneTextColours[5]
        
        
        self.bpmLabel.text = "???"
        
        self.lastUpdatedLabel.text = ""
        self.currentZoneLabel.text = "Zone ??"
        self.heartView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        var keys: NSDictionary?
        
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        if let dict = keys {
            serverToken = (dict["serverToken"] as? String)!
            author = (dict["author"] as? String)!
        }
        
        // Scan for all available CoreBluetooth LE devices
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        
        // Populate with fake data
        //save(126, time: Date())
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? HeartDataTableViewController {
            controller.heartRateZones = self.heartRateZones
            controller.zoneBackgroundColours = self.zoneColours
            controller.zoneTextColours = self.zoneTextColours
        }
    }
    
    // MARK: BLE Scanning
    func scanBLEDevices() {
        
        // Get a list of already connected devices
        let heartRateService = CBUUID.init(string: HEART_RATE_SERVICE_UUID)
        let connectedPeripherals = centralManager?.retrieveConnectedPeripherals(withServices: [heartRateService])
        
        print("Already connected to the following heart rate services:")
        for peripheral in connectedPeripherals! {
            if (peripheral.name?.hasPrefix("SLICE"))! {
                print("We are already connected to a SLICE via another app")
                self.deviceName = "mio"
                self.heartMonitorPeripheral = peripheral
                self.centralManager?.connect(peripheral, options: nil)
            } else if (peripheral.name?.hasPrefix("TICKR"))! {
                self.deviceName = "tickr"
                print("We are already connected to a TICKR via another app")
                self.heartMonitorPeripheral = peripheral
                self.centralManager?.connect(peripheral, options: nil)
            } else {
                print("Connected to \(peripheral.name)")
            }
        }
        
        // Only scan if we've not already connected
        if self.heartMonitorPeripheral == nil {
            
            print("Scanning for BLE devices")
            self.scanButton.setTitle("Scanning...", for: .normal)
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            
            //stop scanning after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { 
                self.stopScanForBLEDevices()
            }
        }
    }
    
    func stopScanForBLEDevices() {
        print("Stopping scan")
        self.scanButton.setTitle("Scan", for: .normal)
        centralManager?.stopScan()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: CBCenteralManagerDelegate
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        print("Connected: \(peripheral.state == CBPeripheralState.connected)")
        
        var name = "unknown"
        if let value = peripheral.name {
            name = value
        }
        
        switch peripheral.state {
        case .connected:
            if self.hasLostConnection {
                self.statusLabel.text = "Reconnected to: \(name)"
                if peripheral == self.lostPeripheral {
                    self.stopScanForBLEDevices()
                }
            } else {
                self.statusLabel.text = "Connected to: \(name)"
            }
            
        case .connecting:
            self.statusLabel.text = "Connectting to: \(name)"
            
        case .disconnected:
            self.statusLabel.text = "Disconnected from: \(name)"
            
        case .disconnecting:
            self.statusLabel.text = "Disconnecting from: \(name)"
        }
        
        if peripheral.state == .connected {
            
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("Found \(localName)")
            if localName.hasPrefix("SLICE") {
                print("It is a SLICE")
                self.deviceName = "mio"
                self.heartMonitorPeripheral = peripheral
                self.centralManager?.connect(peripheral, options: nil)
            }
            
            if localName.hasPrefix("TICKR") {
                print("It is a TICKR")
                self.deviceName = "tickr"
                self.heartMonitorPeripheral = peripheral
                self.centralManager?.connect(peripheral, options: nil)
            }
        }
    
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if peripheral == self.heartMonitorPeripheral {
            self.lostPeripheral = peripheral
            self.heartMonitorPeripheral = nil
            self.statusLabel.text = "Disconnected"
            self.hasLostConnection = true
            // Try and reconnect
            
            self.scanButton.setTitle("Scanning...", for: .normal)
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOff:
            print("CoreBluetooth BLE hardware is powered off")
        
        case .poweredOn:
            print("CoreBluetooth BLE hardware is powered on")
            scanBLEDevices()
            
        case .unauthorized:
            print("CoreBluetooth BLE state is unauthorized")
            
        case .unknown:
            print("CoreBluetooth BLE state is unknown")
            
        case .unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform")
            
        default: break
        }
        
    }
    
    // MARK: CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            print("Discovered service \(service.uuid.uuidString) : \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("Discovered characteristics for \(service.uuid.uuidString) \(service.uuid)")
        
        switch service.uuid.uuidString {
        case HEART_RATE_SERVICE_UUID:
            for aChar in service.characteristics! {
                if aChar.uuid.uuidString == HEART_RATE_MEASUREMENT_CHARACTERSTIC_UUID {
                    self.heartMonitorPeripheral?.setNotifyValue(true, for: aChar)
                    print("Found heart rate measurement characteristic")
                }
                
                if aChar.uuid.uuidString == BODY_LOCATION_CHARACTERSTIC_UUID {
                    self.heartMonitorPeripheral?.readValue(for: aChar)
                    print("Found body sensor location characteristic")
                }
                
                print("Characterstic \(aChar.uuid.uuidString) \(aChar.uuid)")
            }
            
        case DEVICE_INFO_SERVICE_UUID:
            for aChar in service.characteristics! {
                
                if aChar.uuid.uuidString == MANUFACTURER_NAME_CHARACTERSTIC_UUID {
                    heartMonitorPeripheral?.readValue(for: aChar)
                }
                print("Characterstic \(aChar.uuid.uuidString) \(aChar.uuid)")
            }
            
        case BATTERY_SERVICE_UUID:
            for aChar in service.characteristics! {
                if aChar.uuid.uuidString == BATTERY_LEVEL_CHARACTERSTIC_UUID {
                    self.heartMonitorPeripheral?.setNotifyValue(true, for: aChar)
                    print("Found batter level characteristic")
                }
                print("Characterstic \(aChar.uuid.uuidString) \(aChar.uuid)")
            }
            
        default:
            for aChar in service.characteristics! {
                print("Characterstic \(aChar.uuid.uuidString) \(aChar.uuid)")
                //peripheral.setNotifyValue(true, for: aChar)
                if let descriptors = aChar.descriptors {
                    for aDescriptor in descriptors {
                        print("Descriptor \(aDescriptor)")
                    }
                }
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        
        switch characteristic.uuid.uuidString {
        case MANUFACTURER_NAME_CHARACTERSTIC_UUID:
            getManufactureName(characteristic)
            
        case BODY_LOCATION_CHARACTERSTIC_UUID:
            getBodyLocation(characteristic)
            
        case HEART_RATE_MEASUREMENT_CHARACTERSTIC_UUID:
            getHeartBMPData(characteristic, error: error)
            
        case BATTERY_LEVEL_CHARACTERSTIC_UUID:
            getBatteryLevel(characteristic)
            
        default:
            print("updated value for \(characteristic.uuid) : \(characteristic.value)")
        }
    }
    
    // MARK: CBCharacteristic helpers
    func getManufactureName(_ characteristic: CBCharacteristic) {
        let stringValue = String(data: characteristic.value!, encoding: String.Encoding.utf8)!
        self.manufacturerLabel.text = "Manufacture \(stringValue)"
    }

    func getBodyLocation(_ characteristic: CBCharacteristic) {
        if let sensorData = characteristic.value {
            print("We have body location")
            sensorData.withUnsafeBytes {  (pointer: UnsafePointer<UInt8>) in
                print("Body location \(pointer[0])")
                self.locationID = Int(pointer[0])
                let locations = ["other", "chest", "wrist", "finger", "hand", "ear lobe", "foot"]
                
                self.location = locations[self.locationID]
                self.locationLabel.text = "Location \(locations[self.locationID])"
            }
        }
    }
    
    func getBatteryLevel(_ characteristic: CBCharacteristic) {
        if let data = characteristic.value {
            print("We have battery level")
            data.withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) in
                print("Battery level \(pointer[0])")
                self.batteryLevelLabel.text = "Battery \(pointer[0])%"
            })
        }
    }
    
    func getHeartBMPData(_ characteristic: CBCharacteristic, error: Error?) {
        if let sensorData = characteristic.value {
            //print("We have heart data")
            
            
            var bpm = 0
            sensorData.withUnsafeBytes {  (pointer: UnsafePointer<UInt8>) in
                //print("Flags \(pointer[0])")
                
                // SLICE does not return Engery Expended nor RR Interval
                // so no code is currently written to handle those values
                if pointer[0] & 0x01 == 0 {
                    bpm = Int(pointer[1])
                } else {
                    bpm = Int(CFSwapInt16LittleToHost(UInt16(pointer[1])))
                }
            }
            
            print("\(bpm) bpm")
            
            if bpm > sessionMax {
                sessionMax = bpm
                self.sessionMaxLabel.text = "\(sessionMax)"
            }
            
            self.bpmLabel.text = "\(bpm) bpm"
            
            let currentDateTime = Date()
            
            // initialize the date formatter and set the style
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateStyle = .long
        
            for zone in 0...5 {
                let zoneRange = heartRateZones[zone]
                if zoneRange.contains(bpm) {
                    currentZone = zone
                    break
                }
            }
            self.lastUpdatedLabel.text = formatter.string(from: currentDateTime)
            self.currentZoneLabel.text = "Zone \(currentZone)"
            self.heartView.backgroundColor = zoneColours[currentZone]
            save(bpm, time: currentDateTime)
            //postHeartRate(bpm, time: currentDateTime)
        }
    }
    
    // MARK: Actions
    
    @IBAction func scanTapped(_ sender: Any) {
        self.scanBLEDevices()
    }
    
    // CoreData
    func save(_ bpm: Int, time: Date) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "HeartRate", in: managedContext)!
        let heartRate = NSManagedObject(entity: entity, insertInto: managedContext)
        heartRate.setValue(bpm, forKey: "bpm")
        heartRate.setValue(deviceName, forKey: "device")
        heartRate.setValue(locationID, forKey: "location")
        heartRate.setValue(false, forKey: "posted")
        heartRate.setValue(time, forKey: "timestamp")
        
        do {
            try managedContext.save()
            heartData.append(heartRate)
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    
    // Server
    func postHeartRate(_ bpm: Int, time: Date) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        let parameters: Parameters = [
            "device": self.deviceName,
            "location" : self.location,
            "hr": "\(bpm)",
            "author": author,
            "timestamp": formatter.string(from: time)
        ]
        
        /*
        let docsBaseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let heartDataURL = docsBaseURL.appendingPathComponent("heartdata.plist")
        
        heartData.append(parameters)
 */
  
        // Both calls are equivalent
        Alamofire.request("http://188.166.138.93:8881/datasave/\(serverToken)", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                debugPrint(response)
        }
    }
}
