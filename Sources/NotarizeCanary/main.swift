//
//  main.swift
//  NotarizeCanary
//
//  Created by Mafalda on 3/5/21.
//

import ArgumentParser
import Foundation

import Gardener

struct NotarizeCanary: ParsableCommand
{
    @Argument(help: "Path to the app binary, bundle, or pkg", transform: ({return URL(fileURLWithPath: $0)}))
    var appFileURL: URL
    
    @Flag(name: [.customShort("p"),
                 .customLong("installer-package"),
                 .customLong("package"),
                 .customLong("is-installer-package")],
          help: "Set this if you are notarizing an installer package rather than a binary or bundle")
    var isInstallerPackage: Bool = false
    
    func validate() throws
    {
        guard FileManager.default.fileExists(atPath: appFileURL.path)
        else
        {
            throw ValidationError("No file was found at the provided path: \(appFileURL)")
        }
    }
    
    func run()
    {
        let command = Command()
        
        if isInstallerPackage
        {
            command.run("pkgutil", "--check-signature", appFileURL.path)
        }
        else
        {
            command.run("codesign", "-vvv", "--deep", "--strict", appFileURL.path)
        }
        
    }
}

NotarizeCanary.main()

