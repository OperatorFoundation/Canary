//
//  ConnectionTest.swift
//  Canary
//
//  Created by Mafalda on 3/19/19.
//

import Foundation

class ConnectionTest
{
    var testWebAddress: String
    var canaryString: String?
    
    init(testWebAddress: String, canaryString: String?)
    {
        self.testWebAddress = testWebAddress
        self.canaryString = canaryString
    }
    
    func run() -> Bool
    {
        print("📣 Running connection test...")
        
        if let url = URL(string: testWebAddress)
        {
            var taskResponse: HTTPURLResponse?
            var taskData: Data?
            var taskError: Error?
            
            let queue = OperationQueue()
            let op = BlockOperation(block:
            {
                print("Attempting to connect to test site...")
                
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                
                let sessionConfig = URLSessionConfiguration.default
                sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                sessionConfig.urlCache = nil
                let session = URLSession(configuration: sessionConfig)
                let testTask = session.dataTask(with: url)
                {
                    (maybeData, maybeResponse, maybeError) in
                    
                    taskResponse = maybeResponse as? HTTPURLResponse
                    taskData = maybeData
                    taskError = maybeError
                    
                    dispatchGroup.leave()
                }
                
                testTask.resume()
                
                dispatchGroup.wait()
            })
            
            queue.addOperations([op], waitUntilFinished: true)
            
            guard let response = taskResponse
                else { return false}
            
            guard response.statusCode == 200
                else { return false }
            
            print("💕 received status code 200 💕")
            
            //Control Data
            if canaryString != nil
            {
                let controlData = canaryString!.data(using: String.Encoding.utf8)
                
                if let observedData = taskData
                {
                    if observedData == controlData
                    {
                        print("💕 🐥 It works! 🐥 💕")
                        print("Observed data = \(observedData.string)")
                        print("Control data = \(controlData!.string)")
                        return true
                    }
                    else
                    {
                        print("\n🖤  We connected but the data did not match. 🖤")
                        
                        if let observedString = String(data: observedData, encoding: String.Encoding.ascii)
                        {
                            print("Here's what we got back instead: \(observedString)")
                        }
                        
                        return false
                    }
                }
            }
            
            
            if let error = taskError
            {
                print("\nReceived an error while trying to connect to our test web address: \(error)")
            }
            
            return true
        }
        else
        {
            print("\nCould not resolve string to url: \(testWebAddress)")
            return false
        }
    }
}
