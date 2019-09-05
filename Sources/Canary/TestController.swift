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
    
    func runTest(withIP serverIP: String, forTransport transport: Transport) -> TestResult?
    {
        var result: TestResult?

        ///ShapeShifter
        guard ShapeshifterController.sharedInstance.launchShapeshifterClient(serverIP: serverIP, transport: transport) == true
        else
        {
            print("\n❗️ Failed to launch Shapeshifter Client for \(transport) with serverIP: \(serverIP)")
            return nil
        }
        
        //sleep(10)
        
        ///Connection Test
        let connectionTest = ConnectionTest()
        let success = connectionTest.run()
        
        result = TestResult(serverIP: serverIP, testDate: Date(), transport: transport, success: success)
        
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
        let resultString = "\(result.testDate), \(result.serverIP), \(result.transport.name), \(result.success)\n"
        
        guard let resultData = resultString.data(using: .utf8)
            else { return false }
        
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        let outputDirectoryPath = "\(currentDirectoryPath)/\(outputDirectoryName)"
        let resultFilePath = "/\(outputDirectoryPath)/\(resultsFileName)\(getNowAsString()).\(resultsExtension)"
        
        if FileManager.default.fileExists(atPath: resultFilePath)
        {
            // We already have a file at this address let's add out results to the end of it.
            guard let fileHandler = FileHandle(forWritingAtPath: resultFilePath)
                else
            {
                print("\n🛑  Error creating a file handler to write to \(resultFilePath)")
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
            
            // Make sure our output directory exists
            if !FileManager.default.fileExists(atPath: outputDirectoryPath)
            {
                do
                {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: outputDirectoryPath, isDirectory: true), withIntermediateDirectories: true, attributes: nil)
                }
                catch
                {
                    print("\n🛑  Error creating output directory at \(outputDirectoryPath): \(error)")
                    return false
                }
            }
            
            // Save the new file
            let saved = FileManager.default.createFile(atPath: resultFilePath, contents: newFileData, attributes: nil)
            print("Test results saved? \(saved.description)")
            //print("File path: \(resultFilePath)")
            
            return saved
        }
    }
    
    func getNowAsString() -> String
    {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate, .withColonSeparatorInTime]
        var dateString = formatter.string(from: Date())
        dateString = dateString.replacingOccurrences(of: "-", with: "_")
        dateString = dateString.replacingOccurrences(of: ":", with: "_")
        
        return dateString
    }
    
}
