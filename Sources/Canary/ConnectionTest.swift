//
//  ConnectionTest.swift
//  Canary
//
//  Created by Mafalda on 3/19/19.
//

import Foundation

class ConnectionTest
{
    let testWebAddress = "http://127.0.0.1:1234/"
    let canaryString = "Yeah!\n"
    
    func run() -> Bool
    {
        print("\n📣 Running connection test...")
        
        var success = false
        
        //Control Data
        let controlData = canaryString.data(using: String.Encoding.utf8)
        
        if let url = URL(string: testWebAddress)
        {
            var taskData: Data?
            var taskError: Error?
            
            let queue = OperationQueue()
            let op = BlockOperation(block:
            {
                print("\nAttempting to connect to test site...")
                
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                
                let testTask = URLSession.shared.dataTask(with: url, completionHandler:
                {
                    (maybeData, maybeResponse, maybeError) in
                    
                    taskData = maybeData
                    taskError = maybeError
                    
                    dispatchGroup.leave()
                })
                
                testTask.resume()
                
                dispatchGroup.wait()
            })
            
            queue.addOperations([op], waitUntilFinished: true)
            
            if let observedData = taskData
            {
                if observedData == controlData
                {
                    print("\n💕 🐥 It works! 🐥 💕")
                    success = true
                }
                else
                {
                    print("\n🖤  We connected but the data did not match. 🖤")
                    
                    if let observedString = String(data: observedData, encoding: String.Encoding.ascii)
                    {
                        print("Here's what we got back instead: \(observedString)")
                    }
                    
                    success = false
                }
            }
            else
            {
                print("\nUnable to connect to test web address.")
            }
            
            if let error = taskError
            {
                print("\nReceived an error while trying to connect to our test web address: \(error)")
            }
            
            return success
        }
        else
        {
            print("\nCould not resolve string to url: \(testWebAddress)")
            return success
        }
    }
}
