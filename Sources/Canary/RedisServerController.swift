//
//  RedisServerController.swift
//  Canary
//
//  Created by Mafalda on 7/23/19.
//

import Foundation
import Auburn

class RedisServerController
{
    static let sharedInstance = RedisServerController()
    
    // FIXME: Redis version is hardcoded here
    #if os(macOS)
    let redisCliPath = "/usr/local/Cellar/redis/5.0.5/bin/redis-cli"
    let redisServerPath = "/usr/local/Cellar/redis/5.0.5/bin/redis-server"
    let shutdownRedisServerScriptPath = "ShutdownRedisServerScriptMac.sh"
    let launchRedisServerScriptPath = "LaunchRedisServerScriptMac.sh"
    let checkRedisServerScriptPath = "CheckRedisServerScript.sh"
    let killRedisServerScriptPath = "KillRedisServerScript.sh"
    let checkRedisServerPortScriptPath = "CheckRedisServerPortScript.sh"
    let redisConfigPath = "redis.conf"
    #elseif os(Linux)
    // TODO: Where is Redis installed on ubuntu?
    let redisCliPath = "~/usr/redis-cli"
    let redisServerPath = "~/usr/redis-server"
    let shutdownRedisServerScriptPath = "~/Canary/Sources/Resources/ShutdownRedisServerScriptUbuntu.sh"
    let launchRedisServerScriptPath = "~/Canary/Sources/Resources/LaunchRedisServerScriptUbuntu.sh"
    let checkRedisServerScriptPath = "~/Canary/Sources/Resources/CheckRedisServerScript.sh"
    let killRedisServerScriptPath = "~/Canary/Sources/Resources/KillRedisServerScript.sh"
    let checkRedisServerPortScriptPath = "~/Canary/Sources/Resources/CheckRedisServerPortScript.sh"
    let redisConfigPath = "~/Canary/Sources/Resources/redis.conf"
    #endif
    
    var redisProcess:Process!
    
    func launchRedisServer(completion:@escaping (_ completion: ServerCheckResult) -> Void)
    {
        isRedisServerRunning
        {
            (serverIsRunning) in
            
            if serverIsRunning
            {
                completion(.okay(nil))
                return
            }
            else
            {
                self.checkServerPortIsAvailable(completion:
                {
                    (result) in
                    
                    switch result
                    {
                    case .okay( _):
                        print("\nServer port is available")
                        
                        
                        guard FileManager.default.fileExists(atPath: self.redisConfigPath)
                            else
                        {
                            print("Unable to launch Redis server: could not find redis.conf at \(self.redisConfigPath)")
                            completion(.failure("Unable to launch Redis server: could not find redis.conf"))
                            return
                        }
                        
                        guard FileManager.default.fileExists(atPath: self.redisServerPath)
                            else
                        {
                            print("Unable to launch Redis server: could not find redis-server.")
                            completion(.failure("Unable to launch Redis server: could not find redis-server."))
                            return
                        }
                        
                        guard FileManager.default.fileExists(atPath: self.launchRedisServerScriptPath)
                            else
                        {
                            print("Unable to launch Redis server. Could not find the script.")
                            completion(.failure("Unable to launch Redis server. Could not find the script."))
                            return
                        }
                        
                        print("\n👇👇 Running Script 👇👇:\n")
                        
                        #if os(macOS)
                        self.runRedisScript(path: self.launchRedisServerScriptPath, arguments: [self.redisConfigPath])
                        {
                            (hasCompleted) in
                            
                            print("\n🚀 Launch Redis Server Script Complete 🚀")
                            completion(.okay(nil))
                        }
                        #elseif os(Linux)
                        self.runRedisScript(path: self.launchRedisServerScriptPath, arguments: nil)
                        {
                            (hasCompleted) in
                            
                            print("\n🚀 Launch Redis Server Script Complete 🚀")
                            completion(.okay(nil))
                        }
                        #endif
   
                    case .otherProcessOnPort(let name):
                        print("\n🛑  Another process is using our port. Process name: \(name)")
                        completion(result)
                    case .corruptRedisOnPort(let pid):
                        print("\n🛑  Broken redis is already using our port. PID: \(pid)")
                        completion(result)
                    case .failure(let failureString):
                        print("\n🛑  Failed to check server port: \(failureString ?? "")")
                        completion(result)
                    }
                })
            }
        }
    }
    
    func isRedisServerRunning(completion:@escaping (_ completion:Bool) -> Void)
    {
        guard FileManager.default.fileExists(atPath: redisCliPath)
            else
        {
            print("\n🛑  Unable to ping Redis server. Could not find redis-cli at \(redisCliPath).")
            completion(false)
            return
        }
        
        guard FileManager.default.fileExists(atPath: checkRedisServerScriptPath)
            else
        {
            print("\nFailed to find the Check Redis Server Script at \(checkRedisServerScriptPath).")
            completion(false)
            return
        }
        
        let process = Process()
        process.launchPath = checkRedisServerScriptPath
        process.arguments = [redisCliPath]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.terminationHandler =
        {
            (task) in
            
            // Get the data
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            
            print(output ?? "no output")
            
            if output == "PONG\n"
            {
                print("\nWe received a pong, server is already running!!")
                completion(true)
            }
            else
            {
                print("\nNo Pong, launch the server!!")
                completion(false)
            }
        }
        process.waitUntilExit()
        process.launch()
    }
    
    func checkServerPortIsAvailable(completion:@escaping (_ completion: ServerCheckResult) -> Void)
    {
        guard FileManager.default.fileExists(atPath: checkRedisServerScriptPath)
            else
        {
            print("Unable to check the Redis server port. Could not find the script.")
            completion(.failure("Unable to check the Redis server port. Could not find the script."))
            return
        }
        
        let process = Process()
        process.launchPath = checkRedisServerScriptPath
        let pipe = Pipe()
        process.standardOutput = pipe
        process.terminationHandler =
        {
            (task) in
            
            // Get the data
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: String.Encoding.utf8)
            
            if output == ""
            {
                print("\nOur port is empty")
                completion(.okay(nil))
            }
            else
            {
                print("\nReceived a response for our port with lsof: \(output ?? "no output")")
                guard let responseString = output
                    else
                {
                    print("\nlsof response could not be interpreted as a string.")
                    completion(.failure("lsof response could not be interpreted as a string."))
                    return
                }
                
                let responseArray = responseString.split(separator: " ")
                guard responseArray.count > 1
                    else
                {
                    completion(.failure(nil))
                    return
                }
                
                let processName = String(responseArray[0])
                let pid = String(responseArray[1])
                
                if processName == "redis-ser"
                {
                    completion(.corruptRedisOnPort(pid: pid))
                }
                else
                {
                    completion(.otherProcessOnPort(name: processName))
                }
            }
        }
        
        process.launch()
        process.waitUntilExit()
    }
    
    func shutdownRedisServer()
    {
        if redisProcess != nil
        {
            if redisProcess.isRunning
            {
                redisProcess.terminate()
            }
        }
        
        guard FileManager.default.fileExists(atPath: shutdownRedisServerScriptPath)
            else
        {
            print("Unable to shutdown Redis server. Could not find the script.")
            return
        }
        
        #if os(macOS)
        guard FileManager.default.fileExists(atPath: redisCliPath)
            else
        {
            print("Unable to launch Redis server. Could not find redis-cli.")
            return
        }
        print("\n👇👇 Running Script 👇👇:\n")
        
        runRedisScript(path: shutdownRedisServerScriptPath, arguments: [redisCliPath])
        {
            (taskCompleted) in
            
            print("Server has been 🤖 TERMINATED 🤖")
        }
        #elseif os(Linux)
        runRedisScript(path: shutdownRedisServerScriptPath, arguments: nil)
        {
            (taskCompleted) in
            
            print("Server has been 🤖 TERMINATED 🤖")
        }
        #endif  
    }
    
    func killProcess(pid: String, completion:@escaping (_ completion:Bool) -> Void)
    {
        guard FileManager.default.fileExists(atPath: killRedisServerScriptPath)
            else
        {
            print("Unable to kill Redis server. Could not find the script.")
            completion(false)
            return
        }
        
        let process = Process()
        process.launchPath = killRedisServerScriptPath
        process.arguments = [pid]
        process.terminationHandler =
        {
            (task) in
            
            completion(true)
        }
        
        process.launch()
        process.waitUntilExit()
    }
    
    func runRedisScript(path: String, arguments: [String]?, completion:@escaping (_ completion:Bool) -> Void)
    {
        let processQueue = DispatchQueue.global(qos: .background)
        processQueue.async
        {
            print("🚀🚀🚀🚀🚀🚀🚀")
            
            if self.redisProcess == nil
            {
                //Creates a new Process and assigns it to the launchTask property.
                print("\nCreating a new launch process.")
                self.redisProcess = Process()
                
            }
            else
            {
                print("\nLaunch process already running. Terminating current process and creating a new one.")
                self.redisProcess!.terminate()
                self.redisProcess = Process()
            }
            
            self.redisProcess!.launchPath = path
            
            if let arguments = arguments
            {
                self.redisProcess!.arguments = arguments
            }
            
            self.redisProcess!.terminationHandler =
            {
                (task) in
                
                print("\nRedis Script Has Terminated.")
                
                //Main Thread Stuff Here If Needed
                DispatchQueue.main.async(execute:
                {
                    print("\nRedis Script Has Terminated.")
                    completion(true)
                })
            }
            
            self.redisProcess!.launch()
        }
    }
    
    // Redis considers switching databases to be switching between numbered partitions within the same db file.
    // We will be switching instead to a database represented by a completely different file.
    func switchDatabaseFile(withFile fileURL: URL, completion:@escaping (_ completion:Bool) -> Void)
    {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let newDBName = fileURL.lastPathComponent
        let destinationURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent(newDBName)
        
        // Rewrite redis.conf to use the dbfilename for the name of the new .rdb file
        // Setting the dbFilename calls config rewrite with the new name in Redis
        Auburn.dbfilename = newDBName
        //        NotificationCenter.default.post(name: .updateDBFilename, object: nil)
        
        // Issue a SHUTDOWN command to the Redis server
        Auburn.shutdownRedis()
        Auburn.restartRedis()
        
        // Copy the .rdb file into the Redis working directory, as specified in redis.conf (defaults to ./, which is the directory the Redis server was run from)
        /*
         # The working directory.
         #
         # The DB will be written inside this directory, with the filename specified
         # above using the 'dbfilename' configuration directive.
         #
         # The Append Only File will also be created inside this directory.
         #
         # Note that you must specify a directory here, not a file name.
         dir ./
         */
        
        do
        {
            if fileManager.fileExists(atPath: destinationURL.path)
            {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            
            print("\n📂  Copied file from: \n\(fileURL)\nto:\n\(destinationURL)\n")
            // Start Redis
            launchRedisServer
                {
                    (success) in
                    
                    completion(true)
            }
        }
        catch let copyError
        {
            print("\nError copying redis DB file from \(fileURL) to \(currentDirectory):\n\(copyError)")
            // Start Redis
            launchRedisServer
                {
                    (success) in
                    
                    completion(true)
            }
            
            // Reset dbfilename to the default as we failed to copy the new file over
            Auburn.dbfilename = "dump.rdb"
        }
    }
    
    enum ServerCheckResult
    {
        case okay(String?)
        case corruptRedisOnPort(pid: String)
        case otherProcessOnPort(name: String)
        case failure(String?)
    }
}
