//
//  BatchTestController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/23/17.
//
//

import Foundation

class TestController
{
    static let sharedInstance = TestController()
    
    func runTest(forTransport transport: String) -> TestResult?
    {
        var result: TestResult?
        
        //This is a test to verify that the given transport server is running, open vpn servers are not used here
        print("Testing the local machine to see if \(transport) is behaving...")
        ///ShapeShifter
        ShapeshifterController.sharedInstance.launchShapeshifterClient(forTransport: transport)
        
        sleep(10)
        
        ///Connection Test
        let connectionTest = ConnectionTest()
        let success = connectionTest.run()
        
        result = TestResult.init(testDate: Date(), transport: transport, success: success)
        
        ///Cleanup
        print("🛁  🛁  🛁  🛁  Cleanup! 🛁  🛁  🛁  🛁")
        ShapeshifterController.sharedInstance.stopShapeshifterClient()
        
        sleep(5)
        
        return result
    }
    
}
