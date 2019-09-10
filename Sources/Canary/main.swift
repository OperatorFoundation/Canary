import Foundation

//Transports
let obfs4 = Transport(name: "obfs4", port: obfs4ServerPort)
//let meek = Transport(name: "meek", port: <#T##String#>)
let shadowsocks = Transport(name: "shadowsocks", port: shsocksServerPort)
let allTransports = [obfs4, shadowsocks]

func doTheThing(forTransports transports: [Transport])
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
        print("\nPress enter to proceed...")
        _ = readLine()
        print("🍙  Starting test for \(transport) 🍙")
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
                    print("✅  Redis successfully launched.")
                    
                    AdversaryLabController.sharedInstance.launchAdversaryLab(forTransport: transport)
                    
                    sleep(5)
                    
                    if let transportTestResult = TestController.sharedInstance.runTest(withIP: ipString, forTransport: transport)
                    {
                        print("Test result for \(transport):\n\(transportTestResult)\n")
                        AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: transportTestResult)
                    }
                    else
                    {
                        print("\n🛑  Received a nil result when testing \(transport)")
                        AdversaryLabController.sharedInstance.stopAdversaryLab(testResult: nil)
                    }
                    
                    sleep(30)
                    
                    print("Stopped AdversaryLab attempting to shutdown Redis.")
                    RedisServerController.sharedInstance.shutdownRedisServer()
                    {
                        (success) in
                        
                        RedisServerController.sharedInstance.saveDatabaseFile(forTransport: transport, completion:
                        {
                            (didSave) in
                            
                            dispatchGroup.leave()
                        })
                    }
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
