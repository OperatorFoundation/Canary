import Foundation

//Transports
let obfs4 = "obfs4"
let meek = "meek"
let shadowsocks = "shadowsocks"
let allTransports = [obfs4, meek, shadowsocks]

func doTheThing(forTransports transports: [String])
{
    for transport in transports
    {
        AdversaryLabController.sharedInstance.launchAdversaryLab(forTransport: transport)
        
        if let transportTestResult = TestController.sharedInstance.runTest(forTransport: transport)
        {
            print("\nTest result for \(transport):\n\(transportTestResult)\n")
        }
        else
        {
            print("Received a nil result when testing \(transport)")
        }
        
        AdversaryLabController.sharedInstance.stopAdversaryLab()
    }
}

doTheThing(forTransports:[obfs4, shadowsocks])
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
