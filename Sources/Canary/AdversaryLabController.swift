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
    
    func launchAdversaryLab(forTransport transport: Transport)
    {
        print("🔬  Launching Adversary Lab")
        
        let arguments = ["capture", transport.name, "allow", transport.port]
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
    }
    
    func stopAdversaryLab(testResult: TestResult?)
    {
        if clientLaunchTask != nil
        {
            if let result = testResult
            {
                // Before exiting let Adversary Lab know what kind of category this connection turned out to be based on whether or not the test was successful
                let category: String
                
                switch result.success
                {
                case false:
                    category = "blocked"
                case true:
                    category = "allowed"
                }
                
                let pipe = Pipe()
                clientLaunchTask!.standardInput = pipe
                pipe.fileHandleForWriting.write("\(category)\n".data)
            }
            
            // FIXME: terminate() is not yet implemented for Linux
            #if os(macOS)
            clientLaunchTask?.terminate()
            clientLaunchTask?.waitUntilExit()
            #else
            killAll(processToKill: adversaryLabClientProcessName)
            #endif
            clientLaunchTask = nil
        }
    }

}
