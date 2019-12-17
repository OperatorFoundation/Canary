//
//  RethinkDBController.swift
//  Canary
//
//  Created by Mafalda on 12/6/19.
//

import Foundation
import Rethink

struct RethinkDBController
{
    static let sharedInstance = RethinkDBController()
    
    #if os(macOS)
    let rethinkdb = "/usr/local/bin/rethinkdb"
    #else
    let rethinkdb = "/usr/bin/rethinkdb"
    #endif
    
    func launchRethinkDB()
    {
        R.connect(URL(string: "rethinkdb://localhost:28015")!) { (connectEError, _) in
            
            if let rethinkError = connectEError
            {
                print("Error connecting to the rethink database: \(rethinkError)")
            }
        }
    }
    
    func dumpDB(filename: String?)
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
    
    
}
