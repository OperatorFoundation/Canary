import Foundation

/// launch AdversaryLabClient to capture our test traffic, and run a connection test.
/// When testing is complete the transport rdb is moved to a different location so as not to be overwritten ands so that the data is available for testing,
/// and a csv file is saved with the test results.
///
/// - Parameter transports: The list of transports to be tested.
func doTheThing(forTransports transports: [Transport])
{
    guard CommandLine.argc > 1
    else
    {
        print("\nServer IP required for testing")
        return
    }
    
    let ipString = CommandLine.arguments[1]
    
    if CommandLine.argc > 2
    {
        resourcesDirectoryPath = CommandLine.arguments[2]
    }
        
    RethinkDBController.sharedInstance.launchRethinkDB()
    
    for transport in transports
    {
        print("\n 🧪 Starting test for \(transport.name)")
        TestController.sharedInstance.test(transport: transport, serverIPString: ipString, webAddress: nil)
    }
    
//    for webAddress in testWebAddresses
//    {
//        TestController.sharedInstance.test(transport: webTest, serverIPString: ipString, webAddress: webAddress)
//    }
    
    RethinkDBController.sharedInstance.dumpDB(filename: nil)
}

doTheThing(forTransports:allTransports)
ShapeshifterController.sharedInstance.killAllShShifter()

signal(SIGINT)
{
    (theSignal) in
    
    print("Force exited the testing!! 😮")
    
    //Cleanup
    ShapeshifterController.sharedInstance.stopShapeshifterClient()
    //AdversaryLabController.sharedInstance.stopAdversaryLabServer()
    
    exit(0)
}
