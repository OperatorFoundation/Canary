//
//  main.swift
//  Canary
//
//  Created by Mafalda on 1/5/21.
//

import ArgumentParser
import Foundation

import Gardener

let configs = ["ReplicantClientConfig.json",  "meek.json",  "obfs4.json", "shadowsocks.json"]
let canaryTarName = "Canary.tar.gz"

struct BuildForLinux: ParsableCommand
{
    @Argument(help: "IP address for the system to build on.")
    var buildServerIP: String

    @Argument(help: "IP address for the system to test the build on.")
    var testServerIP: String
    
    func validate() throws
    {
        // This pings the server ip and returns nil if it fails
        guard let _ = SSH(username: "root", host: buildServerIP)
        else
        {
            throw ValidationError("'<BuildServerIP>' is not valid.")
        }

        // This pings the server ip and returns nil if it fails
        guard let _ = SSH(username: "root", host: testServerIP)
        else
        {
            throw ValidationError("'<TestServerIP>' is not valid.")
        }
    }
    
    func run()
    {
        buildForLinux()
        testForLinux()
    }

    func buildForLinux()
    {
        //Upload the config files
        guard let scp = SCP(username: "root", host: buildServerIP)
        else
        {
            print("Failed to initialize scp.")
            return
        }
                
        for config in configs
        {
            let source = File.homeDirectory().appendingPathComponent("Documents/Operator/Canary/Sources/Resources/Configs/\(config)")
            print("scp from \(source)")
            guard let _ = scp.upload(remotePath: "Canary/\(config)", localPath: source.path)
            else
            {
                print("SCP Failed to copy the configs to the remote server.")
                return
            }
        }
        
        // Download and build Canary on the remote server
        // Run Package Canary to zip the needed resources
        let result = Bootstrap.bootstrap(username: "root", host: buildServerIP, source: "https://github.com/OperatorFoundation/Canary", branch: "main", target: "PackageCanary", packages: ["libpcap"])
        
        if result
        {
            // Download the tar file from the remote server
            let canaryDestination = File.homeDirectory().appendingPathComponent("Documents/Operator/Canary/\(canaryTarName)")
            guard let _ = scp.download(remotePath: "Canary/\(canaryTarName)", localPath: canaryDestination.path)
            else
            {
                print("SCP Failed to copy the Canary tar file from the remote server.")
                return
            }
            
            print("Finished running BuildForLinux.")
        }
        else
        {
            print("Failed to build Canary")
        }
    }

    func testForLinux()
    {
        //Upload the config files
        guard let scp = SCP(username: "root", host: testServerIP)
        else
        {
            print("Failed to initialize scp.")
            return
        }

        let canaryOrigin = File.homeDirectory().appendingPathComponent("Documents/Operator/Canary/\(canaryTarName)")
        guard let _ = scp.upload(remotePath: "/root/\(canaryTarName)", localPath: canaryOrigin.path)
        else
        {
            print("SCP Failed to copy the Canary tar file from the remote server.")
            return
        }

        guard let ssh = SSH(username: "root", host: testServerIP)
        else
        {
            print("SCP Failed to copy the Canary tar file to the test server.")
            return
        }

        let _ = ssh.untargzip(path: canaryTarName)
        let _ = ssh.remote(command: "Canary/Canary")
    }
}

BuildForLinux.main()
