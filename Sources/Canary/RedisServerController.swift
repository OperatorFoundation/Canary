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
        print("🗃  launchRedisServer called")
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
                        
                        print("👇👇 Running Script 👇👇:\n")
                        self.runLaunchRedisScript()
                        sleep(1)
                        self.isRedisServerRunning
                        {
                            (serverIsRunning) in
                            
                            if serverIsRunning
                            {
                                completion(.okay(nil))
                                return
                            }
                            else
                            {
                                self.launchRedisServer(triedShutdown: false, retryCount: retryCount + 1, completion: completion)
                            }
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
    
    func runLaunchRedisScript()
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
            
            self.redisProcess!.executableURL = URL(fileURLWithPath: launchRedisServerScriptPath, isDirectory: false)

            self.redisProcess!.arguments = [redisConfigPath]
            self.redisProcess!.launch()
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
            print("\n🛑  Failed to find the Check Redis Server Script at \(checkRedisServerScriptPath).")
            print("🤔  Current directory: \(FileManager.default.currentDirectoryPath)")
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
                print("We received a pong, server is already running!!")
                completion(true)
            }
            else
            {
                print("No Pong, launch the server!!")
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
            print("\n🛑  Unable to check the Redis server port. Could not find the script.")
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
                completion(.okay(nil))
            }
            else
            {
                print("\n🛑  Received a response for our port with lsof: \(output ?? "no output")")
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
            print("\n🛑  Unable to shutdown Redis server. Could not find the script.")
            completion(false)
            return
        }
        
        print("👇👇 Running Redis Shutdown Script 👇👇:\n")
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
            print("\n🛑  Unable to kill Redis server. Could not find the script.")
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
                self.redisProcess = Process()
                
            }
            else
            {
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
                
                completion(true)
            }
            
            self.redisProcess!.launch()
        }
    }
    
    // Redis considers switching databases to be switching between numbered partitions within the same db file.
    // We will be switching instead to a database represented by a completely different file.
    func saveDatabaseFile(forTransport transport: Transport, completion:@escaping (_ completion:Bool) -> Void)
    {
        print("Save database file called.")
        let fileManager = FileManager.default
        let destinationURL = rdbFileURL(forTransport: transport)
        let workingRDBFileURL = URL(fileURLWithPath: "./dump.rdb", isDirectory: false) //currentRDBFileURL()
        
        guard fileManager.fileExists(atPath: workingRDBFileURL.path)
            else
        {
            print("\n🛑  We couldn't save the Redis DB file. A file was not found at \(workingRDBFileURL)")
            completion(false)
            return
        }
        
        do
        {
            if rdbFileExists(forTransport: transport)
            {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: workingRDBFileURL, to: destinationURL)
            
            print("📂  Moved file from: \n\(workingRDBFileURL)\nto:\n\(destinationURL)\n")
        }
        catch
        {
            print("📂Error moving redis DB file from:\n\(workingRDBFileURL) to:\n\(destinationURL):\n\(error)")
            completion(false)
            return
        }
        
        completion(true)
    }
    
    func rdbFileURL(forTransport transport: Transport) -> URL
    {
        let fileManager = FileManager.default
        
        #if os(macOS)
        let outputDirectoryPath = "\(fileManager.currentDirectoryPath)/\(outputDirectoryName)"
        #elseif os(Linux)
        let outputDirectoryPath = outputDirectoryName
        #endif
        
        let transportDBFilename = "\(transport.name).rdb"
        let transportDBFileURL = URL(fileURLWithPath: outputDirectoryPath).appendingPathComponent(transportDBFilename)
        
        // Make sure our output directory exists
        if !FileManager.default.fileExists(atPath: outputDirectoryPath)
        {
             try? FileManager.default.createDirectory(at: URL(fileURLWithPath: outputDirectoryPath, isDirectory: true), withIntermediateDirectories: true, attributes: nil)
        }
        
        return transportDBFileURL
    }
    
    func currentRDBFileURL() -> URL
    {
        #if os(macOS)
        let rdbFilePath = "\(FileManager.default.currentDirectoryPath)/dump.rdb"
        #elseif os(Linux)
        let rdbFilePath = "dump.rdb"
        #endif
        
        let currentRDBFileURL = URL(fileURLWithPath: rdbFilePath)
        
        return currentRDBFileURL
    }
    
    func rdbFileExists(forTransport transport: Transport) -> Bool
    {
        let transportDBFileURL = rdbFileURL(forTransport: transport)
        
        if FileManager.default.fileExists(atPath: transportDBFileURL.path)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func loadRDBFile(forTransport transport: Transport)
    {
        if rdbFileExists(forTransport: transport)
        {
            let transportDBFileURL = rdbFileURL(forTransport: transport)
            let workingRDBFileURL = currentRDBFileURL()
            
            if FileManager.default.fileExists(atPath: workingRDBFileURL.path)
            {
                try? FileManager.default.removeItem(at: workingRDBFileURL)
            }
            
            do
            {
                try FileManager.default.moveItem(at: transportDBFileURL, to: workingRDBFileURL)
            }
            catch
            {
                print("\n🛑  Unable to move item at \(transportDBFileURL) to \(workingRDBFileURL)\nerror: \(error)")
            }
        }
    }
    
    func getNowAsString() -> String
    {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        var dateString = formatter.string(from: Date())
        dateString = dateString.replacingOccurrences(of: "-", with: "")
        dateString = dateString.replacingOccurrences(of: ":", with: "")
        
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
