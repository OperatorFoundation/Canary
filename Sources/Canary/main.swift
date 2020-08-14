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

/// launch AdversaryLabClient to capture our test traffic, and run a connection test.
/// When testing is complete the transport rdb is moved to a different location so as not to be overwritten ands so that the data is available for testing,
/// and a csv file is saved with the test results.
///
/// - Parameter transports: The list of transports to be tested.
func doTheThing(forTransports transports: [Transport])
{
    guard CommandLine.argc > 1
    else
    {
        print("\nServer IP required for testing")
        return
    }
    
    let ipString = CommandLine.arguments[1]
    
    if CommandLine.argc > 2
    {
        resourcesDirectoryPath = CommandLine.arguments[2]
    }
            
    for transport in transports
    {
        print("\n 🧪 Starting test for \(transport.name)")
        TestController.sharedInstance.test(transport: transport, serverIPString: ipString, webAddress: nil)
    }
    
    for webAddress in testWebAddresses
    {
        TestController.sharedInstance.test(transport: webTest, serverIPString: ipString, webAddress: webAddress)
    }
    
    // TODO: Zip up the adversary_data directory created by AdversaryLabClient.
    // This directory contains our test results.
    zipResults()
}

doTheThing(forTransports:allTransports)
ShapeshifterController.sharedInstance.killAllShShifter()

signal(SIGINT)
{
    (theSignal) in
    
    print("Force exited the testing!! 😮")
    
    //Cleanup
    ShapeshifterController.sharedInstance.stopShapeshifterClient()
    //AdversaryLabController.sharedInstance.stopAdversaryLabServer()
    
    exit(0)
}
