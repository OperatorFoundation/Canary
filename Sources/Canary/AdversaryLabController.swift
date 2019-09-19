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
    private var pipe = Pipe()
    
    func launchAdversaryLab(forTransport transport: Transport)
    {
        print("🔬  Launching Adversary Lab.")
        
        let arguments = [transport.port]
        
        if clientLaunchTask != nil
        {
            print("🔬  AdversaryLab process isn't nil.")
            clientLaunchTask!.terminate()
        }

        clientLaunchTask = Process()
        clientLaunchTask!.executableURL = URL(fileURLWithPath: adversaryLabClientPath, isDirectory: false)
        clientLaunchTask!.arguments = arguments
        
        // Refresh our pipe just in case we've already used it.
        pipe = Pipe()
        clientLaunchTask!.standardInput = pipe
        print("🔬  Assigned standard input to pipe.")
        
        clientLaunchTask!.launch()
    }
    
    func stopAdversaryLab(testResult: TestResult?)
    {
        print("🔬  Stop AdversaryLab called.")
        if clientLaunchTask != nil
        {
            print("🔬  AdversaryLab process isn't nil.")
            if let result = testResult
            {
                // Before exiting let Adversary Lab know what kind of category this connection turned out to be based on whether or not the test was successful
                let category: String
                
                switch result.success
                {
                case false:
                    category = "block"
                case true:
                    category = "allow"
                }
                
                if clientLaunchTask!.isRunning
                {
                    self.pipe.fileHandleForWriting.write("\(category)\n".data)
                    print("🔬  Wrote \(category) to AdversaryLab.")
                    sleep(10)
                }
                else
                {
                    print("🔬  Unable to tell Adversary Lab what category our test results were because it is no longer running.")
                }
            }
            
            
            // FIXME: terminate() is not yet implemented for Linux
            #if os(macOS)
            print("🔬  Calling terminate on the AdversaryLab process.")
            clientLaunchTask?.terminate()
            clientLaunchTask?.waitUntilExit()
            #else
            print("🔬  Waiting so AdversaryLabClient can save data.")
            sleep(20)
            print("🔬  Calling killall on the AdversaryLab process.")
            killAll(processToKill: adversaryLabClientProcessName)
            #endif
            clientLaunchTask = nil
        }
    }

}
