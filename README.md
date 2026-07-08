# Filemator

A free, open-source macOS menu bar app that watches folders (Downloads by
default) and automatically moves newly downloaded files into other folders
based on rules you define — extension and filename matching, evaluated
first-match-wins.

## Requirements

- macOS 13.0 or later

## Installation

```bash
brew tap moisesnandres/filemator https://github.com/moisesnandres/filemator
brew install --cask filemator
```

## Usage

1. Launch Filemator — it appears as an icon in the menu bar.
2. Click the icon > "Open Filemator" to manage rules and watched folders.
3. On the Rules tab, add a rule (extension and/or filename match + destination folder).
4. On the Watched Folders tab, add any folders you want monitored (Downloads is watched by default).
5. Matching files are moved automatically. View or undo past moves on the History tab.

## Development

Requirements: macOS 13.0+, Xcode 16 or later.

Open `Filemator.xcodeproj` in Xcode and run (Cmd+R).

To run the unit/integration tests without launching the app (the `FilematorUITests` target launches the real built app, which will start watching your actual Downloads folder):

```bash
xcodebuild test -project Filemator.xcodeproj -scheme Filemator -destination 'platform=macOS' -only-testing:FilematorTests
```

## License

MIT — see [LICENSE](LICENSE).
