import Foundation

//Transports
let obfs4 = "obfs4"
let meek = "meek"
let shadowsocks = "shadowsocks"
let allTransports = [obfs4, meek, shadowsocks]

//Stop any possible processes that may be left over from a previous run
//AdversaryLabController.sharedInstance.stopAdversaryLabServer()
//AdversaryLabController.sharedInstance.stopAdversaryLab()

//Now we are running the things. Hooray!
//AdversaryLabController.sharedInstance.launchAdversaryLabServer()

// obfs4
if let obfs4TestResult = TestController.sharedInstance.runTest(forTransport: obfs4)
{
    print("\nTest result for obfs4:\n\(obfs4TestResult)")
    let _ = obfs4TestResult.saveToFile()
}
else
{
    print("Received a nil result when testing obfs4")
}

// ShadowSocks
if let shadowSocksTestResult = TestController.sharedInstance.runTest(forTransport: shadowsocks)
{
    print("\nTest result for shadowsocks:\n\(shadowSocksTestResult)")
    let _ = shadowSocksTestResult.saveToFile()
}

//AdversaryLabController.sharedInstance.stopAdversaryLabServer()
ShapeshifterController.sharedInstance.killAllShShifter()

signal(SIGINT)
{
    (theSignal) in
    
    print("Force exited the testing!! 😮")
    
    //Cleanup
    ShapeshifterController.sharedInstance.stopShapeshifterClient()
    //AdversaryLabController.sharedInstance.stopAdversaryLabServer()
    
    //TODO: Write a Report
    exit(0)
}
