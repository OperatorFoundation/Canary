import Foundation

//Transports
let obfs4 = "obfs4"
let meek = "meek"
let shadowsocks = "shadowsocks"
let allTransports = [obfs4, meek, shadowsocks]

func doTheThing(forTransports transports: [String])
{
    guard CommandLine.argc > 1
    else
    {
        print("\nServer IP:port are required for testing")
        return
    }
    
    let ipString = CommandLine.arguments[1]

    for transport in transports
    {
        let queue = OperationQueue()
        let op = BlockOperation(block:
        {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            RedisServerController.sharedInstance.launchRedisServer
            {
                (result) in
                
                switch result
                {
                case .corruptRedisOnPort(pid: let pid):
                    print("\n🛑  Redis is already running on our port. PID: \(pid)")
                case .failure(let failure):
                    print("\n🛑  Failed to Launch Redis: \(failure ?? "no error given")")
                case .otherProcessOnPort(name: let processName):
                    print("\n🛑  Another process \(processName) is using our port.")
                case .okay(_):
                    print("\n✅  Redis successfully launched.")
                    
                    AdversaryLabController.sharedInstance.launchAdversaryLab(forTransport: transport)
                    
                    if let transportTestResult = TestController.sharedInstance.runTest(withIP: ipString, forTransport: transport)
                    {
                        print("\nTest result for \(transport):\n\(transportTestResult)\n")
                    }
                    else
                    {
                        print("Received a nil result when testing \(transport)")
                    }
                    
                    AdversaryLabController.sharedInstance.stopAdversaryLab()
                    
                    RedisServerController.sharedInstance.saveDatabaseFile(forTransport: transport, completion:
                    {
                        (didSave) in
                        RedisServerController.sharedInstance.shutdownRedisServer()
                        dispatchGroup.leave()
                    })
                }
            }
            
            dispatchGroup.wait()
        })
        
        queue.addOperations([op], waitUntilFinished: true)
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
