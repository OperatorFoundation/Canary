//
//  Constants.swift
//  Canary
//
//  Created by Mafalda on 8/15/19.
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

#if os(macOS)
var resourcesDirectoryPath = "/Users/mafalda/Documents/Operator/Canary/Sources/Resources"
#else
var resourcesDirectoryPath = "/home/mafalda/Canary/Sources/Resources"
#endif

let adversaryLabClientPath = "\(resourcesDirectoryPath)/AdversaryLabClient"
let adversaryLabClientProcessName = "AdversaryLabClient"
let shShifterResourcePath = "\(resourcesDirectoryPath)/shapeshifter-dispatcher"

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
let replicantFilePath = "\(resourcesDirectoryPath)/Configs/ReplicantClientConfig.json"

//Transports
let obfs2 = Transport(name: "obfs2", port: obfs2ServerPort)
let obfs4 = Transport(name: "obfs4", port: obfs4ServerPort)
let obfs4iatMode = Transport(name: "obfs4iatMode", port: obfs4ServerPort)
let shadowsocks = Transport(name: "shadow", port: shsocksServerPort)
let replicant = Transport(name: "Replicant", port: replicantServerPort)
let meek = Transport(name: "meeklite", port: meekServerPort)

let webTest = Transport(name: "webTest", port: "443")
let allTransports = [replicant, obfs4, shadowsocks, webTest]

//let testWebAddresses = [String]()
let testWebAddresses = ["https://www.youtube.com/",
                        "https://www.instagram.com/",
                        "https://www.cnn.com/",
                        "https://www.wikipedia.org/"]

// "https://www.facebook.com/",
//"https://www.reddit.com/",
//"https://twitter.com/home",

let stateDirectoryPath = "TransportState"

let resultsFileName = "CanaryResults"
let resultsExtension = "csv"
let outputDirectoryName = "Output"
