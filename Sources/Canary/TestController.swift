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
            
            // Save this result to a file
            let _ = save(result: result!)
            
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
