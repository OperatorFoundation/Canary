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
        
        guard let ipURL = Bundle.main.url(forResource: "serverIP", withExtension: nil)
            else
        {
            print("\nUnable to find IP File")
            return nil
        }
        do
        {
            let serverIP = try String(contentsOfFile: ipURL.path, encoding: String.Encoding.ascii).replacingOccurrences(of: "\n", with: "")
            
            ///ShapeShifter
            guard ShapeshifterController.sharedInstance.launchShapeshifterClient(forTransport: transport) == true
            else
            {
                return nil
            }
            
            sleep(10)
            
            ///Connection Test
            let connectionTest = ConnectionTest()
            let success = connectionTest.run()
            
            result = TestResult.init(serverIP: serverIP, testDate: Date(), transport: transport, success: success)
            
            ///Cleanup
            print("🛁  🛁  🛁  🛁  Cleanup! 🛁  🛁  🛁  🛁")
            ShapeshifterController.sharedInstance.stopShapeshifterClient()
        }
        catch let error
        {
            print("Failed to run test.")
            print("Error reading serverIP file: \(error)")
        }

        sleep(5)
        return result
    }
    
}
