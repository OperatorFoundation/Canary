//
//  KillAll.swift
//  transport-canary
//
//  Created by Adelita Schule on 7/10/17.
//
//

import Foundation

func killAll(processToKill: String)
{
    print("******* ☠️ KILLALL \(processToKill) CALLED ☠️ *******")
    
    let killTask = Process()
    let executablePath = "/usr/bin/killall"
    
    killTask.executableURL = URL(fileURLWithPath: executablePath, isDirectory: false)
    //Arguments will pass the arguments to the executable, as though typed directly into terminal.
    killTask.arguments = [processToKill]
    
    //Go ahead and run the process/task
    killTask.launch()
    killTask.waitUntilExit()
    sleep(2)
    
    //Do it again, maybe it doesn't want to die.
    
    let killAgain = Process()
    killAgain.executableURL = URL(fileURLWithPath: executablePath, isDirectory: false)
    killAgain.arguments = ["-9", processToKill]
    killAgain.launch()
    killAgain.waitUntilExit()
    sleep(2)
}
