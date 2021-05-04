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
    @Option(name: .shortAndLong, parsing: .next, help: "Set the version number for this release.")
    var version: String = "1.0.0"

//    func validate() throws
//    {
//        guard FileManager.default.fileExists(atPath: appFileURL.path)
//        else
//        {
//            throw ValidationError("No file was found at the provided path: \(appFileURL)")
//        }
//    }
    
    func run()
    {
        let command = Command()
        guard let swift = Swift()
        else
        {
            print("Failed to initialize Swift, we are unable to build our target!")
            return
        }
        
        let swiftBuildResponse = swift.build()
        
        if swiftBuildResponse != nil
        {
            print("Swift build response:")
            print(swiftBuildResponse!.0)
            print(swiftBuildResponse!.1.string)
            print(swiftBuildResponse!.2.string)
        }
        else
        {
            print("SWIFT BUILD RESPONSE WAS NIL")
        }
        
        let buildDir = FileManager.default.currentDirectoryPath
        let pkgRootDir = "\(buildDir)/build/pkgroot"
        
        // the email address of your developer account
        let devAccount = "adelita@operatorfoundation.org"
        
        // the name of your Developer ID installer certificate
        let signature = "Developer ID Installer: Operator Foundation (67Y4NSLDQ3)"
        
        // the label of the keychain item which contains an app-specific password
        let devKeychainLabel = "Developer-altool"
        let password = "@keychain:\(devKeychainLabel)"
        
        // build clean install
        print("## building with Xcode")
        
        // $ xcodebuild -scheme iOS  DSTROOT="/Users/username/Desktop/ReleaseLocation" archive
        guard let installResponse = command.run("xcodebuild", "clean", "install", "-quiet", "DSTROOT=\(pkgRootDir)")
        else
        {
            print("Failed to build a clean install.")
            return
        }

        if let installResponseString = String(data: installResponse.1, encoding: .utf8), !installResponseString.isEmpty
        {
            print("Install response:")
            print(installResponseString)
        }

        if let installResponseError = String(data: installResponse.2, encoding: .utf8), !installResponseError.isEmpty
        {
            print("Install error:")
            print(installResponseError)
            return
        }
        
        // build the pkg
        let pkgPath = "Canary-\(version).pkg"

        print("## building pkg: \(pkgPath)")
        let bundleIdentifier = "org.operatorfoundation.Canary"
        
        guard let buildPKGResponse = command.run("pkgbuild", "--root", pkgRootDir, "--version", version, "--identifier", bundleIdentifier, "--sign", signature, "--install-location", "/Applications", pkgPath)
        else
        {
            print("pkg build failed.")
            return
        }
        
        if let buildPKGResponseString = String(data: buildPKGResponse.1, encoding: .utf8), !buildPKGResponseString.isEmpty
        {
            print("Build pkg response:")
            print(buildPKGResponseString)
        }
        
        if let buildPKGError = String(data: buildPKGResponse.2, encoding: .utf8), !buildPKGError.isEmpty
        {
            print("Build pkg error:")
            print(buildPKGError)
            return
        }
        
        // upload for notarization
        print("## Uploading for notarization.")
        guard notarizeFile(filepath: pkgPath, identifier: bundleIdentifier, username: devAccount, password: password)
        else
        {
            print("Failed to notarize pkg.")
            return
        }
        
        // staple result
        print("## Stapling \(pkgPath)")
        guard let stapleResponse = command.run("xcrun", "stapler", "staple", pkgPath)
        else
        {
            print("Failed to staple notarization to the pkg.")
            return
        }
        
        if let stapleResponseString = String(data: stapleResponse.1, encoding: .utf8), !stapleResponseString.isEmpty
        {
            print("Staple response:")
            print(stapleResponseString)
        }
        
        if let stapleResponseError = String(data: stapleResponse.2, encoding: .utf8), !stapleResponseError.isEmpty
        {
            print("Staple response error:")
            print(stapleResponseError)
            return
        }
        print("## Done!")

        // show the pkg in Finder
        _ = command.run("open", "-R", pkgPath)
    }
    
    func requestStatus(uuid: String, username: String, password: String) -> NotarizationStatus
    {
        let command = Command()
        guard let response = command.run("xcrun",
                            "altool",
                            "--notarization-info", uuid,
                            "--username", username,
                            "--password", password)
        else { return .failed }
        
        print("Received a status response.")
        print("Exit code: \(response.0)")
        print(response.1.string)
        print(response.2.string)
        
        let responseString = response.1.string
        let responseDictionary = parseHttpLikeHeader(headerString: responseString)
        
        if responseDictionary.isEmpty { return .inProgress }
        
        guard let statusString = responseDictionary["Status"] else { return .inProgress }
        guard let notarizationStatus = NotarizationStatus(rawValue: statusString) else { return .failed }
        
        return notarizationStatus
    }
    
    func notarizeFile(filepath: String, identifier: String, username: String, password: String) -> Bool
    {
        let command = Command()
        
        // the 10-digit team id
        let devTeamID = "67Y4NSLDQ3"
        
        //let productname = "Hello"
        // upload file
        print("## uploading \(filepath) for notarization")
        
        let bundleIdentifier = "org.operatorfoundation.Canary"
        
        guard let response = command.run("xcrun", "altool", "--notarize-app", "--primary-bundle-id", bundleIdentifier, "--username", username, "--password", password, "--asc-provider", devTeamID, "--file", filepath)
        else
        {
            print("could not upload for notarization")
            return false
        }
        
        if let responseString = String(data: response.1, encoding: .utf8), !responseString.isEmpty
        {
            // TODO: Print the UUID
            print("Upload for notarization response:")
            print(responseString)
        }
        
        if let responseError = String(data: response.2, encoding: .utf8), !responseError.isEmpty
        {
            print("Notarization error:")
            print(responseError)
            return false
        }
        
        let uuidResponseString = response.1.string
        
        guard !uuidResponseString.isEmpty
        else
        {
            print("Failed to parse notarization response.")
            return false
        }
        
        let uuidLine = uuidResponseString.components(separatedBy: "\n")[1]
        let uuid = uuidLine.components(separatedBy: " ")[2]
        
        print("****UUID: \(uuid)")
        
        // wait for status to be not "in progress" any more
        var currentStatus = NotarizationStatus.inProgress
        
        while currentStatus == .inProgress
        {
            print("Waiting...")
            sleep(10)
            currentStatus = requestStatus(uuid: uuid, username: username, password: password)
        }
        
        if currentStatus == .failed
        {
            print("## could not notarize \(filepath)")
        }
        else
        {
            print("## Notarization complete!")
        }
        
        return true
    }
    
    enum NotarizationStatus: String {
        case inProgress = "in progress"
        case success = "success"
        case failed = "failed"
    }
}

NotarizeCanary.main()

