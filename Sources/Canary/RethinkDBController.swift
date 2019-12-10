//
//  RethinkDBController.swift
//  Canary
//
//  Created by Mafalda on 12/6/19.
//

import Foundation

struct RethinkDBController
{
    static let sharedInstance = RethinkDBController()
    let rethinkdb = "/usr/local/bin/rethinkdb"
    
    func launchRethinkDB()
    {
        let launchTask = Process()
        launchTask.executableURL = URL(fileURLWithPath: rethinkdb, isDirectory: false)
        launchTask.launch()
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
