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

import ArgumentParser
import Foundation

struct CanaryTest: ParsableCommand
{
    @Argument(help: "IP address for the transport server.")
    var serverIP: String
    
    @Argument(help: "Optionally set the path to the directory where Canary's required resources can be found. It is recommended that you only use this if the default directory does not work for you.")
    var resourceDirPath: String?
    
    @Option(help:"Set how many times you would like Canary to run its tests.")
    var runs: Int = 1
    
    func validate() throws
    {
        guard runs >= 1 && runs <= 10
        else
        {
            throw ValidationError("'<runs>' must be at least 1 and no more than 10.")
        }
    }
    
    /// launch AdversaryLabClient to capture our test traffic, and run a connection test.
    ///  a csv file and song data (zipped) are saved with the test results.
    func run()
    {
        if let rPath = resourceDirPath
        {
            resourcesDirectoryPath = rPath
        }
        
        for i in 1...runs
        {
            print("\n***************************\nRunning test batch \(i) of \(runs)\n***************************")
            
            for transport in allTransports
            {
                print("\n 🧪 Starting test for \(transport.name) 🧪\n")
                TestController.sharedInstance.test(name: transport.name, serverIPString: serverIP, port: transport.port, webAddress: nil)
            }
            
            for webTest in allWebTests
            {
                print("\n 🧪 Starting web test for \(webTest.website) 🧪\n")
                TestController.sharedInstance.test(name: webTest.name, serverIPString: serverIP, port: webTest.port, webAddress: webTest.website)
            }
            
            // This directory contains our test results.
            zipResults()
        }
        
        ShapeshifterController.sharedInstance.killAllShShifter()
    }
}

CanaryTest.main()

////doTheThing(forTransports:allTransports)
//ShapeshifterController.sharedInstance.killAllShShifter()
//

signal(SIGINT)
{
    (theSignal) in

    print("Force exited the testing!! 😮")

    //Cleanup
    ShapeshifterController.sharedInstance.stopShapeshifterClient()
    //AdversaryLabController.sharedInstance.stopAdversaryLabServer()

    exit(0)
}


