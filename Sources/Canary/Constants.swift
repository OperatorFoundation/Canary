//
//  Constants.swift
//  Canary
//
//  Created by Mafalda on 8/15/19.
//

import Foundation

var resourcesDirectoryPath = "Sources/Resources"

let adversaryLabClientPath = "\(resourcesDirectoryPath)/AdversaryLabClient"
let adversaryLabClientProcessName = "AdversaryLabClient"
let shShifterResourcePath = "\(resourcesDirectoryPath)/shapeshifter-dispatcher"

let shutdownRedisServerScriptPath = "\(resourcesDirectoryPath)/ShutdownRedisServerScript.sh"
let launchRedisServerScriptPath = "\(resourcesDirectoryPath)/LaunchRedisServerScript.sh"
let checkRedisServerScriptPath = "\(resourcesDirectoryPath)/CheckRedisServerScript.sh"
let killRedisServerScriptPath = "\(resourcesDirectoryPath)/KillRedisServerScript.sh"
let checkRedisServerPortScriptPath = "\(resourcesDirectoryPath)/CheckRedisServerPortScript.sh"
let changeRDBFilenameScriptPath = "\(resourcesDirectoryPath)/ChangeDBFilename.sh"

let obfs2ServerPort = "4567"
let obfs4ServerPort = "1234"
let shsocksServerPort = "2345"
let replicantServerPort = "3456"
let meekServerPort = "443"

//let shSocksServerIPFilePath = "Resources/shSocksServerIP"

let meekOptionsPath = "\(resourcesDirectoryPath)/Configs/meek.json"
let obfs4FilePath = "\(resourcesDirectoryPath)/Configs/obfs4.json"
let obfs4iatFilePath = "\(resourcesDirectoryPath)/Configs/obfs4iatMode.json"
let shSocksFilePath = "\(resourcesDirectoryPath)/Configs/shadowsocks.json"
let replicantFilePath = "\(resourcesDirectoryPath)/Configs/replicant.json"

#if os(macOS)
let redisConfigPath = "\(resourcesDirectoryPath)/redis.conf"
#elseif os(Linux)
let redisConfigPath = "\(resourcesDirectoryPath)/redisUbuntu.conf"
#endif

//Transports
let obfs2 = Transport(name: "obfs2", port: obfs2ServerPort)
let obfs4 = Transport(name: "obfs4", port: obfs4ServerPort)
let obfs4iatMode = Transport(name: "obfs4iatMode", port: obfs4ServerPort)
let shadowsocks = Transport(name: "shadow", port: shsocksServerPort)
let replicant = Transport(name: "Replicant", port: replicantServerPort)
let meek = Transport(name: "meeklite", port: meekServerPort)

let webTest = Transport(name: "webTest", port: "443")
let allTransports = [obfs4iatMode, shadowsocks, obfs4, replicant, obfs2, meek]
let testWebAddresses = ["https://swift.org"]

let stateDirectoryPath = "TransportState"

let resultsFileName = "CanaryResults"
let resultsExtension = "csv"
let outputDirectoryName = "Output"
