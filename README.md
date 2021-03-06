# The Operator Foundation

[Operator](https://operatorfoundation.org) makes useable tools to help people around the world with censorship, security, and privacy.

## Canary


## Getting Started

### Prerequisites

Swift 5.2, included in Xcode 11
Go 1.14 or higher

#### Ubuntu
libcurl4

### Installing

## macOS
Check out the project from Github, and download the dependencies using Swift Package Manager.

```
git clone https://github.com/OperatorFoundation/Canary
cd Canary
swift package update
swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.15"

```

Don't forget to add your configs to the Sources/Resources/Configs directory. Operator does not currently provide transport configs for you.

Config file names should be as follows: 

- meek.json 
- obfs4.json
- shadowsocks.json
- ReplicantClientConfig.json


Clone and build AdversaryLabClientSwift. Then copy the binary into the Canary/Sources/Resources directory.

```
cd ..
git clone https://github.com/OperatorFoundation/AdversaryLabClientSwift.git
cd AdversaryLabClientSwift
swift package update
swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.15"
cp .build/x86_64-apple-macosx/debug/AdversaryLabClientSwift ../Canary/Sources/Resources/AdversaryLabClientSwift
```


Clone and build shapeshifter-dispatcher. Then copy the binary into the Canary/Sources/Resources directory. For more information on building the shapeshifter binary check the [readme](https://github.com/OperatorFoundation/shapeshifter-dispatcher/blob/main/README.md).

```
cd ..
go get -u github.com/OperatorFoundation/shapeshifter-dispatcher
cp shapeshifter-dispatcher ../Canary/Sources/Resources/shapeshifter-dispatcher
```

## Running

Canary is a command line tool and can be run by entering:

```
sudo .build/x86_64-apple-macosx/debug/Canary <transport server IP>
```

## Built With

* [Datable](https://github.com/OperatorFoundation/Datable) - Swift convenience functions to convert between various different types and Data
* [Replicant](https://github.com/OperatorFoundation/shapeshifter-transports/tree/main/transports/Replicant/v2) - Replicant is Operator's Pluggable Transport that can be tuned for each adversary.
* [shapeshifter-dispatcher](https://github.com/OperatorFoundation/shapeshifter-dispatcher) - Provides network protocol shapeshifting technology.
* [AdversaryLabClientSwift](https://github.com/OperatorFoundation/AdversaryLabClientSwift) - Adversary Lab is a service that analyzes captured network traffic to extract statistical properties.

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests.

## Versioning

[SemVer](http://semver.org/) is used for versioning. For the versions available, see the [tags on this repository](https://github.com/OperatorFoundation/AdversaryLab/tags).

## Authors

* **Dr. Brandon Wiley** - *Concept and initial work* - [Operator Foundation](https://OperatorFoundation.org/)
* **Adelita Schule** - *Swift implementation* - [Operator Foundation](adelita@OperatorFoundation.org)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments



