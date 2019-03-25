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
    ///The date the test was run.
    var testDate: Date
    
    ///The transport that was tested.
    var transport: String
    
    //Whether or not the test succeeded.
    var success = false
}

