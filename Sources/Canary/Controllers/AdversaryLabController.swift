//
//  AdversaryLabController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/22/17.
//  MIT License
//
//  Copyright (c) 2020 Operator Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

import AdversaryLabClientCore
import Datable

class AdversaryLabController
{    
    static let sharedInstance = AdversaryLabController()
    
    private let adversaryLabQueue = DispatchQueue(label: "AdversaryLabController")
    private var adversaryLabClient: AdversaryLabClient?
        
    func launchAdversaryLab(transportName: String, port: String)
    {
        adversaryLabClient = AdversaryLabClientCore.AdversaryLabClient(transport: transportName, port: UInt16(string: port), allowBlock: nil)
        
        print("🔬  Launching Adversary Lab.")
        adversaryLabQueue.async {
            self.adversaryLabClient?.startRecording()
        }
    }
    
    func stopAdversaryLab(testResult: TestResult?)
    {
        if let result = testResult
        {
            print("🔬  Stopping Adversary Lab.")
            
            guard adversaryLabClient != nil
            else
            {
                print("🔬  Attempted to stop adversary lab when it is not running.")
                return
            }
            
            // Before exiting let Adversary Lab know what kind of category this connection turned out to be based on whether or not the test was successful
            
            adversaryLabClient?.stopRecording(result.success)
            adversaryLabClient?.saveCaptured()
            
        }
        
        print("🔬  Finished save captured")
        
    }
    
//    func launchAdversaryLab(forTransport name: String, port: String)
//    {
//        print("🔬  Launching Adversary Lab.")
//
//        guard FileManager.default.fileExists(atPath: adversaryLabClientPath)
//        else
//        {
//            print("\n🛑  Failed to find the path for adversary lab at \(adversaryLabClientPath)")
//            return
//        }
//
//        let arguments = [name, port]
//
//        if clientLaunchTask != nil
//        {
//            clientLaunchTask!.terminate()
//        }
//
//        clientLaunchTask = Process()
//        clientLaunchTask!.executableURL = URL(fileURLWithPath: adversaryLabClientPath, isDirectory: false)
//        clientLaunchTask!.arguments = arguments
//
//        // Refresh our pipe just in case we've already used it.
//        pipe = Pipe()
//        clientLaunchTask!.standardInput = pipe
//        clientLaunchTask!.standardOutput = Pipe()
//        clientLaunchTask!.standardError = Pipe()
//        clientLaunchTask!.launch()
//    }
    
//    func stopAdversaryLab(testResult: TestResult?)
//    {
//        sleep(5)
//        if clientLaunchTask != nil
//        {
//            if let result = testResult
//            {
//                // Before exiting let Adversary Lab know what kind of category this connection turned out to be based on whether or not the test was successful
//                let category: String
//
//                switch result.success
//                {
//                case false:
//                    category = "block"
//                case true:
//                    category = "allow"
//                }
//
//                if clientLaunchTask!.isRunning
//                {
//                    let categoryString = "\(category)\n"
//                    let categoryData = categoryString.data
//                    self.pipe.fileHandleForWriting.write(categoryData)
//                    sleep(5)
//                }
//                else
//                {
//                    print("🔬  Unable to tell Adversary Lab what category our test results were because it is no longer running.")
//                }
//            }
//
//
//            // FIXME: terminate() is not yet implemented for Linux
//            #if os(macOS)
//            clientLaunchTask?.terminate()
//            //clientLaunchTask?.waitUntilExit()
//            #else
//            print("🔬  Waiting so AdversaryLabClient can save data.")
//            sleep(5)
//            killAll(processToKill: adversaryLabClientProcessName)
//            #endif
//            clientLaunchTask = nil
//        }
//    }

}
