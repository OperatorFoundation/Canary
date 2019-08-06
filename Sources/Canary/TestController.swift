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
    let resultsFileName = "CanaryResults.csv"
    
    func runTest(withIP serverIP: String, forTransport transport: String) -> TestResult?
    {
        var result: TestResult?

        ///ShapeShifter
        guard ShapeshifterController.sharedInstance.launchShapeshifterClient(serverIP: serverIP, transport: transport) == true
        else
        {
            print("\n❗️ Failed to launch SahpeshifterClient for \(transport)")
            return nil
        }
        
        //sleep(10)
        
        ///Connection Test
        print("\nInitializing connection test.")
        let connectionTest = ConnectionTest()
        let success = connectionTest.run()
        
        result = TestResult.init(serverIP: serverIP, testDate: Date(), transport: transport, success: success)
        
        // Save this result to a file
        let _ = save(result: result!)
        
        ///Cleanup
        print("🛁  🛁  🛁  🛁  Cleanup! 🛁  🛁  🛁  🛁")
        ShapeshifterController.sharedInstance.stopShapeshifterClient()
        
        sleep(5)
        return result
    }
    
    func save(result: TestResult) -> Bool
    {
        let resultString = "\(result.testDate), \(result.serverIP), \(result.transport), \(result.success)\n"
        
        guard let resultData = resultString.data(using: .utf8)
            else { return false }
        
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        let resultFilePath = "\(currentDirectoryPath)/\(resultsFileName)"
        
        if FileManager.default.fileExists(atPath: resultFilePath)
        {
            // We already have a file at this address let's add out results to the end of it.
            guard let fileHandler = FileHandle(forWritingAtPath: resultFilePath)
                else
            {
                print("\nError creating a file handler to write to \(resultFilePath)")
                return false
            }
            
            fileHandler.seekToEndOfFile()
            fileHandler.write(resultData)
            fileHandler.closeFile()
            
            print("Saved test results to file: \(resultFilePath)")
            return true
        }
        else
        {
            // Make a new csv file for our test results
            
            // The first row should be our labels
            let labelRow = "TestDate, ServerIP, Transport, Success\n"
            guard let labelData = labelRow.data(using: .utf8)
                else { return false }
            
            // Append our results to the label row
            let newFileData = labelData + resultData
            
            // Create the new file
            let saved = FileManager.default.createFile(atPath: resultFilePath, contents: newFileData, attributes: nil)
            print("\nAttempted to create file and save test results to file: \(resultFilePath)\nSuccess: \(saved.description)")
            
            return saved
        }
    }
    
}
