//
//  RethinkDBController.swift
//  Canary
//
//  Created by Mafalda on 12/6/19.
//

import Foundation
#if os(macOS)
import Rethink
#endif

struct RethinkDBController
{
    static let sharedInstance = RethinkDBController()
    
    let rethinkdb = "/usr/local/bin/rethinkdb"
    let python3 = "/usr/bin/python3"
    
    func launchRethinkDB()
    {
        #if os(macOS)
        R.connect(URL(string: "rethinkdb://localhost:28015")!) { (connectEError, _) in
            
            if let rethinkError = connectEError
            {
                print("Error connecting to the rethink database: \(rethinkError)")
            }
        }
        #else
        let launchTask = Process()
        launchTask.executableURL = URL(fileURLWithPath: rethinkdb, isDirectory: false)
        launchTask.launch()
        #endif
    }
    
    func dumpDB(filename: String?)
    {
        #if os(macOS)
        macOSDumpDB(filename: filename)
        #else
        linuxDumpDB(filename: filename)
        #endif
    }
    
    func macOSDumpDB(filename: String?)
    {
        let dumpTask = Process()
        dumpTask.executableURL = URL(fileURLWithPath: rethinkdb, isDirectory: false)
        
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        var arguments = ["dump"]
        if filename != nil
        {
            arguments.append("-f")
            arguments.append("\(filename!).tar.gz")
        }
        dumpTask.arguments = arguments
        
        //Go ahead and run the process/task
        dumpTask.launch()
    }
    
    func linuxDumpDB(filename: String?)
    {
        let dumpTask = Process()
        dumpTask.executableURL = URL(fileURLWithPath: python3, isDirectory: false)
        
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        var arguments = [ "-m", "rethinkdb", "dump"]
        if filename != nil
        {
            arguments.append("-f")
            arguments.append("\(filename!).tar.gz")
        }
        dumpTask.arguments = arguments
        
        //Go ahead and run the process/task
        dumpTask.launch()
    }
    
    
}
