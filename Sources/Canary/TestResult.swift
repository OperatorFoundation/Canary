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
    var transport: Transport
    
    //Whether or not the test succeeded.
    var success = false
    
}

