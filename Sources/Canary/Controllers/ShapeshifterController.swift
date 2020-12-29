//
//  ShapeshifterController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/5/17.
//  MIT License
//
//  Copyright (c) 2020 Operator Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

class ShapeshifterController
{
    private var launchTask: Process?
    static let sharedInstance = ShapeshifterController()
    
    func launchShapeshifterClient(serverIP: String, transport: Transport) -> Bool
    {
        if let arguments = shapeshifterArguments(serverIP: serverIP, transport: transport)
        {
            print("👀 launchShapeShifterDispatcher called. Transport: \(transport.name)")
            
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
            
            let exeURL = URL(fileURLWithPath: shShifterResourcePath, isDirectory: false)
            launchTask!.executableURL = exeURL
            launchTask!.arguments = arguments
            print("Arguments:")
            print(arguments.joined(separator: " "))
            
            do
            {
                print("Trying to run dispatcher...")
                try launchTask!.run()
            }
            catch let error
            {
                print("Failed to run dispatcher: \(error)")
                return false
            }
            
            print("Sleeping...")
            sleep(3)
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
                options = getObfs4Options(iatMode: false)
            case obfs4iatMode:
                options = getObfs4Options(iatMode: true)
            case shadowsocks:
                options = getShadowSocksOptions()
            case meek:
                options = getMeekOptions()
            case replicant:
                options = replicantFilePath
            default:
                options = nil
            }

            //IP and Port for our PT Server
            processArguments.append("-target")
            processArguments.append("\(serverIP):\(transport.port)")
            
            //Here is our list of transports (more than one would launch multiple proxies)
            let transportName: String
            if transport == obfs4iatMode
            {
                transportName = obfs4.name
            }
            else
            {
                transportName = transport.name
            }
            processArguments.append("-transports")
            processArguments.append(transportName)
            
            // All transports other than obfs2 require options to be provided
            if transport != obfs2
            {
                guard options != nil
                    else { return nil }
                
                
                if transport == replicant
                {
                    guard FileManager.default.fileExists(atPath: replicantFilePath)
                        else
                    {
                        print("\n🛑  Unable to find Replicant File at path: \(replicantFilePath)")
                        return nil
                    }
                    
                    processArguments.append("-optionsFile")
                    processArguments.append(options!)
                }
                else
                {
                    // This should use generic options based on selected transport
                    // Parameters needed by the specific transport being used
                    processArguments.append("-options")
                    processArguments.append(options!)
                }
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
            processArguments.append("-ptversion")
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
    
    func getObfs4Options(iatMode: Bool) -> String?
    {
        let obfs4OptionsData: Data
        
        if iatMode
        {
            guard FileManager.default.fileExists(atPath: obfs4iatFilePath)
                else
            {
                print("\n🛑  Unable to find obfs4 File at path: \(obfs4iatFilePath)")
                return nil
            }
            
            do
            {
                obfs4OptionsData = try Data(contentsOf: URL(fileURLWithPath: obfs4iatFilePath, isDirectory: false), options: .uncached)
            }
            catch
            {
                print("\n⁉️ Unable to locate the needed obfs4 options ⁉️.")
                return nil
            }
        }
        else
        {
            guard FileManager.default.fileExists(atPath: obfs4FilePath)
                else
            {
                print("\n🛑  Unable to find obfs4 File at path: \(obfs4FilePath)")
                return nil
            }
            
            do
            {
                obfs4OptionsData = try Data(contentsOf: URL(fileURLWithPath: obfs4FilePath, isDirectory: false), options: .uncached)
            }
            catch
            {
                print("\n⁉️ Unable to locate the needed obfs4 options ⁉️.")
                return nil
            }
        }
        
        let rawOptions = String(data: obfs4OptionsData, encoding: String.Encoding.ascii)
        let obfs4Options = rawOptions?.replacingOccurrences(of: "\n", with: "")
        return obfs4Options
        
        
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
