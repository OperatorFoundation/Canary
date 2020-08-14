//
//  BatchTestController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/23/17.
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

class TestController
{
    static let sharedInstance = TestController()
    
    
    /// Launches shapeshifter dispatcher with the transport, runs a connection test, and then saves the results to a csv file.
    ///
    /// - Parameters:
    ///   - serverIP: A string value indicating the IPV4 address of the transport server.
    ///   - transport: The information needed to indicate which transport we are testing.
    /// - Returns: A TestResult value that indicates whether or not the connection test was successful. This is the same test result information that is also saved to a timestamped csv file.
    func runTransportTest(serverIP: String, forTransport transport: Transport) -> TestResult?
    {
        var result: TestResult?

        ///ShapeShifter
        guard ShapeshifterController.sharedInstance.launchShapeshifterClient(serverIP: serverIP, transport: transport) == true
        else
        {
            print("\n❗️ Failed to launch Shapeshifter Client for \(transport) with serverIP: \(serverIP)")
            return nil
        }
                
        ///Connection Test
        let testWebAddress = "http://127.0.0.1:1234/"
        let canaryString = "Yeah!\n"
        let connectionTest = ConnectionTest(testWebAddress: testWebAddress, canaryString: canaryString)
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
    
    /// Tests ability to connect to a given web address without the use of transports
    func runWebTest(serverIP: String, transport: Transport, webAddress: String) -> TestResult?
    {
        var result: TestResult?
        
        ///Connection Test
        let connectionTest = ConnectionTest(testWebAddress: webAddress, canaryString: nil)
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
    
    /// Saves the provided test results to a csv file with a filename that contains a timestamp.
    /// If a file with this name already exists it will append the results to the end of the file.
    ///
    /// - Parameter result: The test result information to be saved. The type is a TestResult struct.
    /// - Returns: A boolean value indicating whether or not the results were saved successfully.
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
    
    func test(transport: Transport, serverIPString: String, webAddress: String?)
    {
//        print("\nPress enter to proceed...")
//       _ = readLine()
       let queue = OperationQueue()
       let op = BlockOperation(block:
       {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            AdversaryLabController.sharedInstance.launchAdversaryLab(forTransport: transport)
            sleep(5)
            
            if webAddress == nil
            {
                if let transportTestResult = self.runTransportTest(serverIP: serverIPString, forTransport: transport)
                {
                    //print("Test result for \(transport.name):\n\(transportTestResult)\n")
                    sleep(20)
                    AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: transportTestResult)
                    dispatchGroup.leave()
                }
                else
                {
                    print("\n🛑  Received a nil result when testing \(transport.name)")
                    sleep(10)
                    AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: nil)
                    dispatchGroup.leave()
                }
            }
            else
            {
                if let webTestResult = self.runWebTest(serverIP: serverIPString, transport: transport, webAddress: webAddress!)
                {
                    //print("Test result for \(transport.name):\n\(webTestResult)\n")
                    sleep(20)
                    AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: webTestResult)
                    dispatchGroup.leave()
                }
                else
                {
                    print("\n🛑  Received a nil result when testing \(transport.name)")
                    sleep(10)
                    AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: nil)
                    dispatchGroup.leave()
                }
            }
           
           dispatchGroup.wait()
       })
       
       queue.addOperations([op], waitUntilFinished: true)
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