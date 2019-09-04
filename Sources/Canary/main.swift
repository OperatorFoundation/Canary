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
        var transportPort: String
        
        switch transport
        {
        case shadowsocks:
            transportPort = shsocksServerPort
        case obfs4:
            transportPort = obfs4ServerPort
        default:
            print("Trying to launch adversary lab client for \(transport) but the correct port is unknown")
            continue
        }
        
        print("\nWaiting for user to press enter...")
        _ = readLine()
        print("\n🍙  Starting test for \(transport) 🍙")
        let queue = OperationQueue()
        let op = BlockOperation(block:
        {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            RedisServerController.sharedInstance.loadRDBFile(forTransport: transport)
            RedisServerController.sharedInstance.launchRedisServer()
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
                    
                    AdversaryLabController.sharedInstance.launchAdversaryLab(forTransport: transport, usingPort: transportPort)
                    
                    sleep(5)
                    
                    if let transportTestResult = TestController.sharedInstance.runTest(withIP: ipString, forTransport: transport)
                    {
                        print("\nTest result for \(transport):\n\(transportTestResult)\n")
                    }
                    else
                    {
                        print("Received a nil result when testing \(transport)")
                    }
                    
                    sleep(30)
                    AdversaryLabController.sharedInstance.stopAdversaryLab()
                    print("\nStopped AdversaryLab attempting to shutdown Redis.")
                    RedisServerController.sharedInstance.shutdownRedisServer()
                    {
                        (success) in
                        
                        print("\nReceived callback from shutdownRedisServer attempting to save DB file.")
                        RedisServerController.sharedInstance.saveDatabaseFile(forTransport: transport, completion:
                        {
                            (didSave) in
                            
                            print("\nReturned from saveDatabaseFile.")
                            dispatchGroup.leave()
                        })
                    }
                }
            }
            
            print("\nStarting dispatch group wait for \(transport) test...")
            dispatchGroup.wait()
            print("\nFinished waiting for \(transport) test dispatch group. ⭐️")
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
