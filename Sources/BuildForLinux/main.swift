//
//  main.swift
//  Canary
//
//  Created by Mafalda on 1/5/21.
//

import ArgumentParser
import Foundation

import Gardener

struct BuildForLinux: ParsableCommand
{
    @Argument(help: "IP address for the system to build on.")
    var serverIP: String
    
    func validate() throws
    {
        // This pings the server ip and returns nil if it fails
        guard let _ = SSH(username: "root", host: serverIP)
        else
        {
            throw ValidationError("'<ServerIP>' is not valid.")
        }
    }
    
    func run()
    {
        buildForLinux()
    }

    func buildForLinux()
    {
        // Download and build Canary on the remote server
        // Run Package Canary to zip the needed resources
        let result = Bootstrap.bootstrap(username: "root", host: serverIP, source: "https://github.com/OperatorFoundation/Canary", branch: "main", target: "PackageCanary", packages: ["libpcap"])
        
        if result
        {
            print("Canary successfully built.")
            
            // Download the zip file from the remote server
            guard let scp = SCP(username: "root", host: serverIP)
            else
            {
                print("Failed to initialize scp.")
                return
            }
            
            guard let _ = scp.download(remotePath: "Canary/Canary.zip", localPath: "Canary.zip")
            else
            {
                print("SCP Failed to copy the Canary zip file from the remote server.")
                return
            }
        }
        else
        {
            print("Failed to build Canary")
        }
    }
}

BuildForLinux.main()



