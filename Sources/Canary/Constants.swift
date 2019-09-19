//
//  Constants.swift
//  Canary
//
//  Created by Mafalda on 8/15/19.
//

import Foundation

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
//let shSocksServerIPFilePath = "Resources/shSocksServerIP"

let meekOptionsPath = "\(resourcesDirectoryPath)/Configs/meek.json"
let obfs4FilePath = "\(resourcesDirectoryPath)/Configs/obfs4.json"
let shSocksFilePath = "\(resourcesDirectoryPath)/Configs/shadowsocks.json"

let redisConfigPath = "\(resourcesDirectoryPath)/redis.conf"

let stateDirectoryPath = "TransportState"

let resultsFileName = "CanaryResults"
let resultsExtension = "csv"
let outputDirectoryName = "Output"
