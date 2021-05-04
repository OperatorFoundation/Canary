//
//  main.swift
//  PackageCanary
//
//  Created by Mafalda on 1/5/21.
//

import Foundation

import Gardener

let configs = ["ReplicantClientConfig.json",  "meek.json",  "obfs4.json", "shadowsocks.json"]
let destinationConfigsPath = "Canary/Sources/Resources/Configs"
let destinationCanaryDirectoryPath = "Canary"
let sourceCanaryBinaryPath = ".build/x86_64-unknown-linux-gnu/debug/Canary"
let destinationCanaryBinaryPath = "Canary/Canary"
let sourceShapeshifterPath = "Sources/Resources/shapeshifter-dispatcher"
let destinationShapeshifterPath = "Canary/Sources/Resources/shapeshifter-dispatcher"
let destinationResourcesPath = "Canary/Sources/Resources"
let canaryTarName = "Canary.tar.gz"

func main()
{
    // Install libpcap
    guard let _ = Apt.install("libpcap-dev")
    else
    {
        print("Failed to install libpcap.")
        return
    }
    
    guard buildDispatcher()
    else
    {
        print("Failed to build dispatcher.")
        return
    }
    
    // Check to see if the Canary directory already exists
    if File.exists(destinationCanaryDirectoryPath)
    {
        // Remove the old directory
        guard File.delete(atPath: destinationCanaryDirectoryPath)
        else
        {
            print("Failed to delete the directory at \(destinationCanaryBinaryPath)")
            return
        }
    }
    
    // Create the Canary directory and its subdirectories
    guard File.makeDirectory(atPath: destinationConfigsPath)
    else
    {
        print("Failed to make a directory at \(destinationConfigsPath)")
        return
    }
    
    //Copy shapeshifter-dispatcher and Canary binaries into the Resources folder
    guard File.copy(sourcePath: sourceShapeshifterPath, destinationPath: destinationShapeshifterPath)
    else
    {
        print("Failed to copy shapeshifter binary from \(sourceShapeshifterPath) to \(destinationShapeshifterPath).")
        return
    }
  
    // FIXME: Currently the path on our test server for Linux is /root/swift-5.3.2-RELEASE-ubuntu20.04/usr/bin/swift Swift.build is failing
    guard let swift = Swift()
    else
    {
        print("Failed to initialize Swift.")
        return
    }
    
    let response = swift.build()
    if response == nil
    {
        print("nil response from build.swift")
    }
    else
    {
        let (exitCode, responseData, errorData) = response!
        print("swift build response: \(exitCode), \(responseData.string), \(errorData)")
    }
    
    // Copy Canary Binary into our destination folder
    guard File.copy(sourcePath: sourceCanaryBinaryPath, destinationPath: destinationCanaryBinaryPath)
    else
    {
        print("Failed to copy Canary binary from \(sourceCanaryBinaryPath) to \(destinationCanaryBinaryPath)")
        return
    }
    
    // Copy our needed supporting libraries into our destination folder
    // TODO: Path is hard-coded "swift-5.3.2-RELEASE-ubuntu20.04/usr/lib/swift/linux/"
    let libraryPath = "/root/swift-5.3.2-RELEASE-ubuntu20.04/usr/lib/swift/linux"
    
    guard let libraries = File.contentsOfDirectory(atPath: libraryPath)
    else
    {
        print("Current directory: \(File.currentDirectory())")
        print("Library path: \(libraryPath)")
        return
    }
    
    for library in libraries
    {
        if !File.copy(sourcePath: "\(libraryPath)/\(library)", destinationPath: "\(destinationCanaryDirectoryPath)/\(library)")
        {
            print("Failed to copy library from \(libraryPath)/\(library) to \(destinationCanaryDirectoryPath)/\(library)")
        }
        
        print("📚 Copied \(libraryPath)/\(library) to \(destinationCanaryDirectoryPath)/\(library). 📚")
    }

    // Copy config files into the configs directory
    for config in configs
    {
        guard File.copy(sourcePath: config, destinationPath: "\(destinationConfigsPath)/\(config)")
        else
        {
            print("Failed to copy config from \(config) to \(destinationConfigsPath)/\(config)")
            return
        }
    }
    
    // Check to see if there is an old zip file already, and delete it if there is
    if File.exists(canaryTarName)
    {
        guard File.delete(atPath: canaryTarName)
        else
        {
            print("Failed to delete \(canaryTarName)")
            return
        }
        
    }
    
    // Create tar.gz of our new directory
    guard File.targzip(name: canaryTarName, directoryPath: destinationCanaryDirectoryPath)
    else
    {
        print("Failed to tar \(destinationCanaryDirectoryPath)")
        return
    }
    
    // Delete the directory now that we are done with it
    guard File.delete(atPath: destinationCanaryDirectoryPath)
    else
    {
        print("Failed to delete \(destinationCanaryDirectoryPath)")
        return
    }
}

func buildDispatcher() -> Bool
{
    // Install Go
    guard Go.install()
    else
    {
        print("Failed to install golang")
        return false
    }
    
    // Clone and build Dispatcher
    let go = Go()
    guard let shapeshifterPath = go.buildFromRepository(repositoryPath: "https://github.com/OperatorFoundation/shapeshifter-dispatcher", branch: "main", target: "shapeshifter-dispatcher")
    else
    {
        print("Failed to clone and build shapeshifter.")
        return false
    }
    
    // Copy Dispatcher to the Canary Resources Directory
    guard File.copy(sourcePath: shapeshifterPath, destinationPath: "Sources/Resources/shapeshifter-dispatcher")
    else
    {
        print("Failed to copy the shapeshifter binary from \(shapeshifterPath) to Sources/Resources/shapeshifter-dispatcher")
        return false
    }
    
    return true
}

main()

