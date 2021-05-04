Thanks to help from [scriptingosx.com](https://scriptingosx.com/2019/09/notarize-a-command-line-tool/)

### Prerequisites
- Set release signing of the tool to 'Developer ID Application'.
- Enable 'Hardened Runtime'.
- Change the 'Installation Build Products Location' to `$SRCROOT/build/pkgroot` (you should add this directory to your .gitignore).
