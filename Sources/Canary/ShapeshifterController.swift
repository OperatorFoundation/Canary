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
    let ptServerPort = "1234"
    let shsocksServerPort = "2345"
    let serverIPFileName = "serverIP"
    let shShifterResourcePath = "shapeshifter-dispatcher"
    //let shSocksServerIPFilePath = "Resources/shSocksServerIP"
    let obfs4FileName = "obfs4.json"
    let meekOptionsPath = "Resources/meek.json"
    let shSocksFileName = "shadowsocks.json"
    let stateDirectoryPath = "TransportState"
    static let sharedInstance = ShapeshifterController()
    
    func launchShapeshifterClient(forTransport transport: String) -> Bool
    {
        if let arguments = shapeshifterArguments(forTransport: transport)
        {
            print("\n👀 LaunchShapeShifterDispatcher")
            
            if launchTask == nil
            {
                //Creates a new Process and assigns it to the launchTask property.
                print("\nCreating a new launch process.")
                launchTask = Process()
                
            }
            else
            {
                print("\nLaunch process already running. Terminating current process and creating a new one.")
                launchTask!.terminate()
                launchTask = Process()
            }
            
            //The launchPath is the path to the executable to run.
            guard FileManager.default.fileExists(atPath: shShifterResourcePath)
            else
            {
                print("\nFailed to find the path for shapeshifter-dispatcher")
                return false
            }
            
            print("\nFound shapeshifter-dispatcher")
            launchTask!.launchPath = shShifterResourcePath
            launchTask!.arguments = arguments
            launchTask!.launch()
            
            return launchTask!.isRunning
        }
        else
        {
            print("\nFailed to launch Shapeshifter Client.\nCould not create/find the transport state directory path, which is required.")
            
            return false
        }
    }
    
    func stopShapeshifterClient()
    {
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
        print("******* ☠️ KILLALL ShShifters CALLED ☠️ *******")
        
        let killTask = Process()
        
        //The launchPath is the path to the executable to run.
        killTask.launchPath = "/usr/bin/killall"
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        killTask.arguments = [shShifterResourcePath]
        
        //Go ahead and launch the process/task
        killTask.launch()
        
        killTask.waitUntilExit()
    }
    
    func shapeshifterArguments(forTransport transport: String) -> [String]?
    {
        if let stateDirectory = createTransportStateDirectory()
        {
            var options: String?

            guard let ipURL = Bundle.main.url(forResource: serverIPFileName, withExtension: nil)
            else
            {
                print("\nUnable to find IP File")
                return nil
            }
            
            do
            {
                let serverIP = try String(contentsOfFile: ipURL.path, encoding: String.Encoding.ascii).replacingOccurrences(of: "\n", with: "")
                
                //List of arguments for Process/Task
                var processArguments: [String] = []
                
                //TransparentTCP is our proxy mode.
                processArguments.append("-transparent")
                
                //Puts Dispatcher in client mode.
                processArguments.append("-client")
                
                if transport == meek
                {
                    options = getMeekOptions()
                    
                    //Dummy data to get around meek server bug
                    processArguments.append("-target")
                    processArguments.append("127.0.0.1:123")
                }
                else if transport == obfs4
                {
                    options = getObfs4Options()
                    
                    //IP and Port for our PT Server
                    processArguments.append("-target")
                    processArguments.append("\(serverIP):\(ptServerPort)")
                }
                else if transport == shadowsocks
                {
                    options = getShadowSocksOptions()
                    
                    //Use Shadowsocks port
                    processArguments.append("-target")
                    processArguments.append("\(serverIP):\(shsocksServerPort)")
                }
                
                if options == nil
                {
                    //Something's wrong, let's get out of here.
                    return nil
                }
                
                //Here is our list of transports (more than one would launch multiple proxies)
                processArguments.append("-transports")
                
                if transport == shadowsocks
                {
                    processArguments.append("shadow")
                }
                else if transport == meek
                {
                        processArguments.append("meeklite")
                }
                else
                {
                    processArguments.append(transport)
                }
                
                //This should use generic options based on selected transport
                //Paramaters needed by the specific transport being used
                processArguments.append("-options")
                processArguments.append(options!)
                
                //Creates a directory if it doesn't already exist for transports to save needed files
                processArguments.append("-state")
                processArguments.append(stateDirectory)
                
                /// -logLevel string
                //Log level (ERROR/WARN/INFO/DEBUG) (default "ERROR")
                processArguments.append("-logLevel")
                processArguments.append("DEBUG")
                
                //Log to TOR_PT_STATE_LOCATION/dispatcher.log
                processArguments.append("-enableLogging")
                
                /// -ptversion string
                //Specify the Pluggable Transport protocol version to use
                //We are using Pluggable Transports version 2.0
                processArguments.append("-ptversion")
                processArguments.append("2")
                
                //Port for shapeshifter client to listen on
                processArguments.append("-proxylistenaddr")
                processArguments.append("127.0.0.1:1234")
                
                return processArguments
            }
            catch
            {
                print("\nUnable to locate the server IP.")
                return nil
            }
            
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
            print("⁉️ Unable to locate the needed meek options ⁉️.")
            return nil
        }
    }
    
    func getObfs4Options() -> String?
    {
        guard let optionsURL = Bundle.main.url(forResource: obfs4FileName, withExtension: nil)
            else
        {
            print("\nUnable to find obfs4 File")
            return nil
        }
        
        do
        {
            let obfs4OptionsData = try Data(contentsOf: URL(fileURLWithPath: optionsURL.path, isDirectory: false), options: .uncached)
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
        guard let optionsURL = Bundle.main.url(forResource: shSocksFileName, withExtension: nil)
            else
        {
            print("\nUnable to find shadowsocks File")
            return nil
        }
        
        do
        {
            let shSocksOptionsData = try Data(contentsOf: optionsURL, options: .uncached)
            let rawOptions = String(data: shSocksOptionsData, encoding: String.Encoding.ascii)
            let shSocksOptions = rawOptions?.replacingOccurrences(of: "\n", with: "")
            return shSocksOptions
        }
        catch
        {
            print("⁉️ Unable to locate the needed shadowsocks options ⁉️.")
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
