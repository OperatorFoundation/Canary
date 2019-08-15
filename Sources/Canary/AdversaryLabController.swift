//
//  AdversaryLabController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/22/17.
//
//

import Foundation
///sudo bin/AdversaryLabClient capture obfs4 allow 1234

class AdversaryLabController
{    
    static let sharedInstance = AdversaryLabController()
    private var clientLaunchTask: Process?
    private var serverLaunchTask: Process?
    
    func launchAdversaryLab(forTransport transport: String)
    {
        let arguments = ["capture", transport, "allow", "1234"]
        if clientLaunchTask == nil
        {
            //Creates a new Process and assigns it to the launchTask property.
            clientLaunchTask = Process()
        }
        else
        {
            clientLaunchTask!.terminate()
            clientLaunchTask = Process()
        }
        
        clientLaunchTask!.executableURL = URL(fileURLWithPath: adversaryLabClientPath, isDirectory: false)
        clientLaunchTask!.arguments = arguments
        clientLaunchTask!.launch()
//        do
//        {
//            try clientLaunchTask!.run()
//        }
//        catch
//        {
//            print("\n⏹  Error running launchAdversaryLab task: \(error)")
//            return
//        }
//        
//        print("\n⏺  Launched Adversary Lab at \(adversaryLabClientPath), with arguments: \(arguments)")
    }
    
    func stopAdversaryLab()
    {
        if clientLaunchTask != nil
        {
            clientLaunchTask?.terminate()
            print("\nStarting wait until exit for stopAdversaryLab.")
            clientLaunchTask?.waitUntilExit()
            print("\nFinished wait until exit for stopAdversaryLab.")
            clientLaunchTask = nil
        }
        
        killAll(processToKill: adversaryLabClientProcessName)
    }

}
