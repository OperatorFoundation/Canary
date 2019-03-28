//
//  TestResult.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/5/17.
//
//

import Foundation

struct TestResult
{
    // The IP of the server we are testing
    var serverIP: String
    
    ///The date the test was run.
    var testDate: Date
    
    ///The transport that was tested.
    var transport: String
    
    //Whether or not the test succeeded.
    var success = false
    
    func saveToFile() -> Bool
    {
        let resultString = "Test Date: \(testDate), Server IP: \(serverIP), Transport: \(transport), Success: \(success)\n"
        
        guard let resultData = resultString.data(using: .utf8)
            else { return false }
        
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        let resultFilePath = "\(currentDirectoryPath)/CanaryResults.txt"
        
        if FileManager.default.fileExists(atPath: resultFilePath)
        {
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
            
            let saved = FileManager.default.createFile(atPath: resultFilePath, contents: resultData, attributes: nil)
            print("\nAttempted to create file and save test results to file: \(resultFilePath)\nSuccess: \(saved.description)")
            return saved
        }
    }
}

