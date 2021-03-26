//
//  main.swift
//  LaunchReplicantServer
//
//  Created by Mafalda on 2/24/21.
//

import ArgumentParser
import Foundation

import Gardener
import Transmission

struct LaunchReplicantServer: ParsableCommand
{
    @Argument(help: "IP address for the system to run the Replicant server on.")
    var serverIP: String
    
    @Argument(help: "The port that this Replicant server should listen on.")
    var serverPort: String
    
    @Argument(help:"The path to the Replicant server configuration file. The file name will be used as the server name.")
    var configFilePath: String
        
    static var serverName = "Replicant"
    
    func validate() throws
    {
        guard FileManager.default.fileExists(atPath: configFilePath)
        else
        {
            throw ValidationError("No file was found at the provided path: \(configFilePath)")
        }
    }
    
    mutating func run()
    {
        // Use the config file name for the server name
        LaunchReplicantServer.serverName = URL(fileURLWithPath: configFilePath, isDirectory: false).deletingPathExtension().lastPathComponent
        
        launchReplicantServer()
    }
    
    func launchReplicantServer()
    {
        // This pings the server ip and returns nil if it fails
        guard let remoteSSH = SSH(username: "root", host: serverIP)
        else
        {
            print("'<ServerIP>' \(serverIP) is not valid.")
            return
        }
        
        guard let scp = SCP(username: "root", host: serverIP)
        else
        {
            print("Failed to initialize scp.")
            return
        }
        
        guard scpConfig(scp: scp)
        else { return }
        
        guard scpSupervisorConfig(scp: scp)
        else { return }
                
        guard let (_, _, _) = remoteSSH.remote(command: "supervisorctl start \(LaunchReplicantServer.serverName)")
        else
        {
            print("Failed to run command supervisorctl start \(LaunchReplicantServer.serverName)")
            return
        }
        
        guard let _ = remoteSSH.remote(command: "ufw allow \(serverPort)")
        else
        {
            print("Failed to run the command ufw allow \(serverPort)")
            return
        }
        
        // This pings the server ip and returns nil if it fails
        // TODO: Use transmission to make a connection and see if we have successfully created a server for this port
//        guard let connection = Transmission.Connection(host: serverIP, port: Int(string: serverPort), type: .tcp)
//        else
//        {
//            print("Failed to connect to the new server.")
//            return
//        }
        
        print("💅🏻 Finished launching the Replicant server \(LaunchReplicantServer.serverName) at \(serverIP) listening on port \(serverPort) 💅🏻")
    }
    
    func scpConfig(scp: SCP) -> Bool
    {
        //Upload the config files
        guard let _ = scp.upload(remotePath: "transportConfigs/\(LaunchReplicantServer.serverName).json", localPath: configFilePath)
        else
        {
            print("Failed to scp server config to remote server.")
            return false
        }
        
        return true
    }
    
    func scpSupervisorConfig(scp: SCP) -> Bool
    {
        // Create the config
        guard let configURL = createSupervisorConfig()
        else { return false }
        
        // Upload the config
        guard let _ = scp.upload(remotePath: "/etc/supervisor/conf.d/\(LaunchReplicantServer.serverName).conf", localPath: configURL.path)
        else
        {
            print("Failed to scp supervisor config to remote server.")
            return false
        }
        
        // Delete the local file as it is no longer needed
        let _ = File.delete(atPath: configURL.path)
        
        return true
    }
    
    func createSupervisorConfig() -> URL?
    {
        let supervisorConfigString = #"""
        [program:\#(LaunchReplicantServer.serverName)]
        command=/root/goProjects/shapeshifter-dispatcher/shapeshifter-dispatcher -server -transparent -ptversion 2.1 -transports Replicant -state state -bindaddr Replicant-0.0.0.0:\#(serverPort) -orport 127.0.0.1:9090 -extorport 127.0.0.1:3334 -logLevel DEBUG -enableLogging -optionsFile "/root/transportConfigs/\#(LaunchReplicantServer.serverName).json"
        directory=/root/go
        autostart=true
        autorestart=true
        stderr_logfile=/var/log/\#(LaunchReplicantServer.serverName).err.log
        stdout_logfile=/var/log/\#(LaunchReplicantServer.serverName).out.log
        """#
        
        let configsURL = URL(fileURLWithPath: configFilePath, isDirectory: false).deletingLastPathComponent()
        let supervisorConfigFileURL = configsURL.appendingPathComponent("\(LaunchReplicantServer.serverName).conf")
        
        do
        {
            try supervisorConfigString.write(to: supervisorConfigFileURL, atomically: true, encoding: .utf8)
            return supervisorConfigFileURL
        }
        catch
        {
            print("Failed to write supervisor config to disk.")
            return nil
        }
    }
}

LaunchReplicantServer.main()

