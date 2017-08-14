//
//  ViewController.swift
//  LKNWearable
//
//  Created by Andrew Sage on 05/07/2017.
//  Copyright © 2017 Living Knowledge Network. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var bpmLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var manufacturerLabel: UILabel!
    var centralManager: CBCentralManager? = nil
    var slicePeripheral: CBPeripheral? = nil

    let SLICE_HEART_RATE_SERVICE_UUID = "180D"
    let SLICE_DEVICE_INFO_SERVICE_UUID = "180A"
    let SLICE_BATTERY_SERVICE_UUID = "180F"
    
    let SLICE_MANUFACTURER_NAME_CHARACTERSTIC_UUID = "2A29"
    let SLICE_MEASUREMENT_CHARACTERSTIC_UUID = "2A37"
    let SLICE_BODY_LOCATION_CHARACTERSTIC_UUID = "2A38"
    
    let SLICE_BATTERY_LEVEL_CHARACTERSTIC_UUID = "2A19"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Scan for all available CoreBluetooth LE devices
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: BLE Scanning
    func scanBLEDevices() {
        
        // Get a list of already connected devices
        let heartRateService = CBUUID.init(string: SLICE_HEART_RATE_SERVICE_UUID)
        let connectedPeripherals = centralManager?.retrieveConnectedPeripherals(withServices: [heartRateService])
        
        print("Already connected to the following heart rate services:")
        for peripheral in connectedPeripherals! {
            if (peripheral.name?.hasPrefix("SLICE"))! {
                print("We are already connected to a SLICE via another app")
                self.slicePeripheral = peripheral
                self.centralManager?.connect(peripheral, options: nil)
            }
        }
        
        // Only scan if we've not already connected
        if self.slicePeripheral == nil {
            
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
            self.statusLabel.text = "Connected to: \(name)"
            
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
                self.slicePeripheral = peripheral
                self.centralManager?.connect(peripheral, options: nil)
            }
        }
    
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
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
            print("Discovered service \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("Discovered characteristics for \(service.uuid.uuidString) \(service.uuid)")

        if service.uuid.uuidString == SLICE_HEART_RATE_SERVICE_UUID {
            for aChar in service.characteristics! {
                if aChar.uuid.uuidString == SLICE_MEASUREMENT_CHARACTERSTIC_UUID {
                    self.slicePeripheral?.setNotifyValue(true, for: aChar)
                    print("Found heart rate measurement characteristic")
                }
                
                if aChar.uuid.uuidString == SLICE_BODY_LOCATION_CHARACTERSTIC_UUID {
                    self.slicePeripheral?.readValue(for: aChar)
                    print("Found body sensor location characteristic")
                }
            }
        }
        
        if service.uuid.uuidString == SLICE_DEVICE_INFO_SERVICE_UUID {
            for aChar in service.characteristics! {
                
                if aChar.uuid.uuidString == SLICE_MANUFACTURER_NAME_CHARACTERSTIC_UUID {
                    slicePeripheral?.readValue(for: aChar)
                }
                print("Characterstic \(aChar.uuid.uuidString) \(aChar.uuid)")
            }
        }
        
        if service.uuid.uuidString == SLICE_BATTERY_SERVICE_UUID {
            for aChar in service.characteristics! {
                print("Characterstic \(aChar.uuid.uuidString) \(aChar.uuid)")
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        
        switch characteristic.uuid.uuidString {
        case SLICE_MANUFACTURER_NAME_CHARACTERSTIC_UUID:
            getManufactureName(characteristic)
            
        case SLICE_BODY_LOCATION_CHARACTERSTIC_UUID:
            getBodyLocation(characteristic)
            
        case SLICE_MEASUREMENT_CHARACTERSTIC_UUID:
            getHeartBMPData(characteristic, error: error)
            
        default:
            print("updated value for \(characteristic.uuid)")
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
            }
        }
    }
    
    func getHeartBMPData(_ characteristic: CBCharacteristic, error: Error?) {
        if let sensorData = characteristic.value {
            //print("We have heart data")
            var bpm = 0
            sensorData.withUnsafeBytes {  (pointer: UnsafePointer<UInt8>) in
                if pointer[0] & 0x01 == 0 {
                    bpm = Int(pointer[1])
                } else {
                    bpm = Int(CFSwapInt16LittleToHost(UInt16(pointer[1])))
                }
            }
            
            self.bpmLabel.text = "\(bpm) bpm"
        }
    }
    
    // MARK: Actions
    
    @IBAction func scanTapped(_ sender: Any) {
        self.scanBLEDevices()
    }
}

