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
    var redisProcess:Process!
    
    func launchRedisServer(triedShutdown: Bool = false, retryCount: Int = 0, completion:@escaping (_ completion: ServerCheckResult) -> Void)
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
                        
                        guard FileManager.default.fileExists(atPath: redisConfigPath)
                            else
                        {
                            print("Unable to launch Redis server: could not find redis.conf at \(redisConfigPath)")
                            completion(.failure("Unable to launch Redis server: could not find redis.conf"))
                            return
                        }
                        
                        guard FileManager.default.fileExists(atPath: launchRedisServerScriptPath)
                            else
                        {
                            print("Unable to launch Redis server. Could not find the script.")
                            completion(.failure("Unable to launch Redis server. Could not find the script."))
                            return
                        }
                        
                        print("\n👇👇 Running Script 👇👇:\n")
                        
                        self.runRedisScript(path: launchRedisServerScriptPath, arguments: [redisConfigPath])
                        {
                            (hasCompleted) in
                            
                            print("\n🚀 Launch Redis Server Script Complete 🚀")
                            completion(.okay(nil))
                        }
   
                    case .otherProcessOnPort(let name):
                        print("\n🛑  Another process is using our port. Process name: \(name)")
                        completion(result)
                    case .corruptRedisOnPort(let pid):
                        print("\n🛑  Broken redis is already using our port. PID: \(pid)")
                        self.handleCorruptRedis(triedShutdown: triedShutdown, retryCount: retryCount, pid: pid, completion: completion)
                    case .failure(let failureString):
                        print("\n🛑  Failed to check server port: \(failureString ?? "")")
                        completion(result)
                    }
                })
            }
        }
    }
    
    func handleCorruptRedis(triedShutdown: Bool, retryCount: Int, pid: String, completion:@escaping (_ completion: ServerCheckResult) -> Void)
    {
        if retryCount > 2
        {
            completion(.failure("Maximum tries reached while trying to kill corrupt Redis on port. PID: \(pid)"))
            return
        }
        
        if triedShutdown
        {
            self.killProcess(pid: pid)
            {
                (didKill) in
                
                self.launchRedisServer(triedShutdown: true, retryCount: retryCount + 1, completion: completion)
            }
        }
        else
        {
            shutdownRedisServer
            {
                (success) in
                
                self.launchRedisServer(triedShutdown: true, retryCount: retryCount, completion: completion)
            }
        }
    }
    
    func isRedisServerRunning(completion:@escaping (_ completion:Bool) -> Void)
    {
        guard FileManager.default.fileExists(atPath: checkRedisServerScriptPath)
            else
        {
            print("\nFailed to find the Check Redis Server Script at \(checkRedisServerScriptPath).")
            completion(false)
            return
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: checkRedisServerScriptPath, isDirectory: false)
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
        process.executableURL = URL(fileURLWithPath: checkRedisServerScriptPath, isDirectory: false)
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
    
    func shutdownRedisServer(completion: @escaping (Bool) -> Void)
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
            completion(false)
            return
        }
        
        print("\n👇👇 Running Redis Shutdown Script 👇👇:\n")
        #if os(macOS)
        runRedisScript(path: shutdownRedisServerScriptPath, arguments: nil)
        {
            (taskCompleted) in
            
            print("Server has been 🤖 TERMINATED 🤖")
            completion(true)
        }
        #elseif os(Linux)
        runRedisScript(path: shutdownRedisServerScriptPath, arguments: nil)
        {
            (taskCompleted) in
            
            print("Server has been 🤖 TERMINATED 🤖")
            completion(true)
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
        process.executableURL = URL(fileURLWithPath: killRedisServerScriptPath, isDirectory: false)
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
            
            self.redisProcess!.executableURL = URL(fileURLWithPath: path, isDirectory: false)
            
            if let arguments = arguments
            {
                self.redisProcess!.arguments = arguments
            }
            
            self.redisProcess!.terminationHandler =
            {
                (task) in
                
                print("\nRedis Script Has Terminated.")
                completion(true)
            }
            
            self.redisProcess!.launch()
        }
    }
    
    // Redis considers switching databases to be switching between numbered partitions within the same db file.
    // We will be switching instead to a database represented by a completely different file.
    func saveDatabaseFile(forTransport transportName: String, completion:@escaping (_ completion:Bool) -> Void)
    {
        print("\nSave database file called.")
        let fileManager = FileManager.default
        
        #if os(macOS)
        let rdbFilePath = fileManager.currentDirectoryPath
        #elseif os(Linux)
        let rdbFilePath = "/var/lib/redis"
        #endif
        
        let currentDate = getNowAsString()
        let newDBName = "\(transportName)_\(currentDate).rdb"
        let outputDirectoryPath = "\(rdbFilePath)/\(outputDirectoryName)"
        let destinationURL = URL(fileURLWithPath: outputDirectoryPath).appendingPathComponent(newDBName)
        let currentRDBFilePath = "\(rdbFilePath)/dump.rdb"
        
        guard fileManager.fileExists(atPath: currentRDBFilePath)
        else
        {
            print("\nWe couldn't save the Redis DB file. The filename was not found at \(currentRDBFilePath)")
            completion(false)
            return
        }
        
        let currentRDBFileURL = URL(fileURLWithPath: currentRDBFilePath)
        
        print("\n📂  Trying to move file from: \n\(currentRDBFileURL)\nto:\n\(destinationURL)\n")
        
        // Make sure our output directory exists
        if !FileManager.default.fileExists(atPath: outputDirectoryPath)
        {
            do
            {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: outputDirectoryPath, isDirectory: true), withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                print("Error creating output directory at \(outputDirectoryPath): \(error)")
                return
            }
        }
        
        do
        {
            if fileManager.fileExists(atPath: destinationURL.path)
            {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: currentRDBFileURL, to: destinationURL)
            
            print("\n📂  Moved file from: \n\(currentRDBFileURL)\nto:\n\(destinationURL)\n")
        }
        catch
        {
            print("\nError moving redis DB file from:\n\(currentRDBFileURL) to:\n\(destinationURL):\n\(error)")
            completion(false)
            return
        }
        
        completion(true)
    }
    
    func getNowAsString() -> String
    {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        var dateString = formatter.string(from: Date())
        dateString = dateString.replacingOccurrences(of: "-", with: "")
        dateString = dateString.replacingOccurrences(of: ":", with: "")
        
        print("\n⏰  Now as String is: \(dateString)")
        return dateString
    }
    
    enum ServerCheckResult
    {
        case okay(String?)
        case corruptRedisOnPort(pid: String)
        case otherProcessOnPort(name: String)
        case failure(String?)
    }
}
