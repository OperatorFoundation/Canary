//
//  ShapeshifterController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/5/17.
//
//

import Foundation

class ShapeshifterController
{
    private var launchTask: Process?
    static let sharedInstance = ShapeshifterController()
    
    func launchShapeshifterClient(serverIP: String, transport: Transport) -> Bool
    {
        if let arguments = shapeshifterArguments(serverIP: serverIP, transport: transport)
        {
            print("👀 LaunchShapeShifterDispatcher")
            print("\(transport), serverIP: \(serverIP)")
            //print("Arguments: \(arguments)")
            
            if launchTask == nil
            {
                //Creates a new Process and assigns it to the launchTask property.
                launchTask = Process()
                
            }
            else
            {
                launchTask!.terminate()
                launchTask = Process()
            }
            
            guard FileManager.default.fileExists(atPath: shShifterResourcePath)
            else
            {
                print("\n🛑  Failed to find the path for shapeshifter-dispatcher")
                return false
            }
            
            launchTask!.executableURL = URL(fileURLWithPath: shShifterResourcePath, isDirectory: false)
            launchTask!.arguments = arguments
            launchTask!.launch()
            sleep(1)
            print("shapeshifter-dispatcher launchTask.isRunning 🏃🏻‍♀️🏃‍♂️ = \(launchTask!.isRunning)")

            return launchTask!.isRunning
        }
        else
        {
            print("\n🛑  Failed to launch Shapeshifter Client.\nCould not create/find the transport state directory path, which is required.")
            
            return false
        }
    }
    
    func stopShapeshifterClient()
    {
        print("Terminating Shapeshifter launch task...")
        
        if launchTask != nil
        {
            // FIXME: terminate() is not yet implemented for Linux
            #if os(macOS)
            launchTask?.terminate()
            launchTask?.waitUntilExit()
            #else
            killAllShShifter()
            #endif
            launchTask = nil
        }
    }
    
    func killAllShShifter()
    {
        print("☠️ KILLALL ShShifters CALLED ☠️")
        
        let killTask = Process()
        let killTaskExecutableURL = URL(fileURLWithPath: "/usr/bin/killall", isDirectory: false)
        killTask.executableURL = killTaskExecutableURL
        
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        killTask.arguments = [shShifterResourcePath]
        
        //Go ahead and run the process/task
        killTask.launch()
        killTask.waitUntilExit()
    }
    
    func shapeshifterArguments(serverIP: String, transport: Transport) -> [String]?
    {
        if let stateDirectory = createTransportStateDirectory()
        {
            var options: String?

            //List of arguments for Process/Task
            var processArguments: [String] = []
            
            //TransparentTCP is our proxy mode.
            processArguments.append("-transparent")
            
            //Puts Dispatcher in client mode.
            processArguments.append("-client")
            
            switch transport
            {
            case obfs4:
                options = getObfs4Options()
            case shadowsocks:
                options = getShadowSocksOptions()
            case replicant:
                options = getReplicantOptions()
            case meek:
                options = getMeekOptions()
            default:
                options = nil
            }

            //IP and Port for our PT Server
            processArguments.append("-target")
            processArguments.append("\(serverIP):\(transport.port)")
            
            //Here is our list of transports (more than one would launch multiple proxies)
            processArguments.append("-transports")
            processArguments.append(transport.name)
            
            // All transports other than obfs2 require options to be provided
            if transport != obfs2
            {
                guard options != nil
                    else { return nil }
                
                // This should use generic options based on selected transport
                // Paramaters needed by the specific transport being used
                processArguments.append("-options")
                processArguments.append(options!)
            }
            
            // Creates a directory if it doesn't already exist for transports to save needed files
            processArguments.append("-state")
            processArguments.append(stateDirectory)
            
            // Log level (ERROR/WARN/INFO/DEBUG) (default "ERROR")
            processArguments.append("-logLevel")
            processArguments.append("DEBUG")
            
            // Log to TOR_PT_STATE_LOCATION/dispatcher.log
            processArguments.append("-enableLogging")
            
            // Specify the Pluggable Transport protocol version to use
            // We are using Pluggable Transports version 2.0
            processArguments.append("-version")
            processArguments.append("2.1")
            
            // Port for shapeshifter client to listen on
            processArguments.append("-proxylistenaddr")
            processArguments.append("127.0.0.1:1234")
            
            return processArguments
        }
        else
        {
            return nil
        }
    }
    
    func getMeekOptions() -> String?
    {
        do
        {
            let meekOptionsData = try Data(contentsOf: URL(fileURLWithPath: meekOptionsPath, isDirectory: false), options: .uncached)
            let rawOptions = String(data: meekOptionsData, encoding: String.Encoding.ascii)
            let meekOptions = rawOptions?.replacingOccurrences(of: "\n", with: "")
            return meekOptions
        }
        catch
        {
            print("\n⁉️ Unable to locate the needed meek options ⁉️.")
            return nil
        }
    }
    
    func getObfs4Options() -> String?
    {
        guard FileManager.default.fileExists(atPath: obfs4FilePath)
            else
        {
            print("\n🛑  Unable to find obfs4 File at path: \(obfs4FilePath)")
            return nil
        }
        
        do
        {
            let obfs4OptionsData = try Data(contentsOf: URL(fileURLWithPath: obfs4FilePath, isDirectory: false), options: .uncached)
            let rawOptions = String(data: obfs4OptionsData, encoding: String.Encoding.ascii)
            let obfs4Options = rawOptions?.replacingOccurrences(of: "\n", with: "")
            return obfs4Options
        }
        catch
        {
            print("\n⁉️ Unable to locate the needed obfs4 options ⁉️.")
            return nil
        }
    }
    
    func getShadowSocksOptions() -> String?
    {
        guard FileManager.default.fileExists(atPath: shSocksFilePath)
            else
        {
            print("\n🛑  Unable to find shadowsocks File")
            return nil
        }
        
        do
        {
            let optionsURL = URL(fileURLWithPath: shSocksFilePath)
            let shSocksOptionsData = try Data(contentsOf: optionsURL, options: .uncached)
            let rawOptions = String(data: shSocksOptionsData, encoding: String.Encoding.ascii)
            let shSocksOptions = rawOptions?.replacingOccurrences(of: "\n", with: "")
            return shSocksOptions
        }
        catch
        {
            print("\n⁉️ Unable to locate the needed shadowsocks options ⁉️.")
            print(error)
            return nil
        }
    }
    
    func getReplicantOptions() -> String?
    {
        guard FileManager.default.fileExists(atPath: replicantFilePath)
            else
        {
            print("\n🛑  Unable to find Replicant File at path: \(replicantFilePath)")
            return nil
        }
        
        do
        {
            let optionsURL = URL(fileURLWithPath: replicantFilePath)
            let replicantOptionsData = try Data(contentsOf: optionsURL, options: .uncached)
            let rawOptions = String(data: replicantOptionsData, encoding: String.Encoding.ascii)
            let replicantOptions = rawOptions?.replacingOccurrences(of: "\n", with: "")
            return replicantOptions
        }
        catch
        {
            print("\n⁉️ Unable to locate the needed Replicant options ⁉️.")
            print(error)
            return nil
        }
    }
    
    func createTransportStateDirectory() ->String?
    {
        do
        {
            try FileManager.default.createDirectory(atPath: stateDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            return stateDirectoryPath
        }
        catch let queueDirError
        {
            print(queueDirError)
            return nil
        }
     }
    
}
