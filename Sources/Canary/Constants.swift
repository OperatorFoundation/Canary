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

let obfs4ServerPort = "1234"
let shsocksServerPort = "2345"
let replicantServerPort = "3456"
//let shSocksServerIPFilePath = "Resources/shSocksServerIP"

let meekOptionsPath = "\(resourcesDirectoryPath)/Configs/meek.json"
let obfs4FilePath = "\(resourcesDirectoryPath)/Configs/obfs4.json"
let shSocksFilePath = "\(resourcesDirectoryPath)/Configs/shadowsocks.json"
let replicantFilePath = "\(resourcesDirectoryPath)/Configs/replicant.json"

let redisConfigPath = "\(resourcesDirectoryPath)/redis.conf"

//Transports
let obfs4 = Transport(name: "obfs4", port: obfs4ServerPort)
let shadowsocks = Transport(name: "shadowsocks", port: shsocksServerPort)
let replicant = Transport(name: "replicant", port: replicantServerPort)
let webTest = Transport(name: "webTest", port: "443")
let allTransports = [obfs4, shadowsocks]
let testWebAddresses = ["https://swift.org"]

let stateDirectoryPath = "TransportState"

let resultsFileName = "CanaryResults"
let resultsExtension = "csv"
let outputDirectoryName = "Output"
