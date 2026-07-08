# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Filemator is a free, open-source macOS menu bar app (macOS 13+) that watches
folders (Downloads by default) and automatically moves newly downloaded
files into other folders based on user-defined rules (extension and/or
filename substring matching, first-match-wins).

## Commands

Requires macOS, Xcode 16+.

Run unit/integration tests (do **not** run the full test plan / `FilematorUITests`
target — it launches the real built app, which starts watching the developer's
actual Downloads folder):

```bash
xcodebuild test -project Filemator.xcodeproj -scheme Filemator -destination 'platform=macOS' -only-testing:FilematorTests
```

Run a single test:

```bash
xcodebuild test -project Filemator.xcodeproj -scheme Filemator -destination 'platform=macOS' -only-testing:FilematorTests/RuleEngineTests/test_firstMatch_returnsFirstMatchingRule_stoppingEvaluation
```

Lint (SwiftLint config at `.swiftlint.yml`, excludes `.build`/`DerivedData`):

```bash
swiftlint
```

There's a single scheme (`Filemator`) and no CI workflow yet — the README
notes future GitHub Actions release/Homebrew Cask distribution is planned
but not yet built.

## Architecture

Single-target SwiftUI app — deliberately **not** a split daemon+GUI. The
watcher runs in-process for the app's lifetime; the app registers itself as
a login item (`LoginItemManager`, via `SMAppService.mainApp`) so in practice
it's always running once installed. See `docs/superpowers/specs/2026-07-07-filemator-design.md`
for the full rationale (a LaunchAgent+XPC split was considered and rejected
as unneeded complexity).

**Data flow:** `FilematorApp` owns a single `AppState` (`@MainActor`,
`ObservableObject`), injected into both the `MenuBarExtra` scene
(`MenuBarView`) and the main `WindowGroup` (`MainWindowView`). `AppState` is
the sole coordinator — it owns one `FolderWatcher` per watched folder,
applies rules on new-file events, and drives `Mover` + `HistoryStore`. Views
don't talk to `Services/` or `Stores/` directly.

**Watch → move pipeline** (`AppState.handleNewFile` → `applyRules`):
1. `FolderWatcher` (FSEvents via `DispatchSourceFileSystemObject` on
   `open(path, O_EVTONLY)`) diffs directory listings on write events, skips
   known in-progress download extensions (`.crdownload`, `.download`,
   `.part`, `.tmp`), and debounces (~300ms) per filename before firing
   `onNewFile`.
2. `RuleEngine.firstMatch` walks `[Rule]` in order and returns the first
   rule whose `Rule.matches(fileURL:)` passes — extension match (if
   `extensions` non-empty) AND filename-contains match (if `nameContains`
   set). Order = priority; reordering in the UI reorders the array.
3. `Mover.move` creates the destination directory if needed and renames on
   collision (`file (2).pdf`, `file (3).pdf`, ...) — never overwrites.
4. Outcome (success/failure) is recorded as a `HistoryEntry` via
   `HistoryStore`. `AppState.undo(_:)` reverses a successful entry by moving
   the file back, failing gracefully (not silently) if the source is now
   occupied or the destination file is gone.

**Persistence:** `RulesStore`, `WatchedFoldersStore`, `HistoryStore` each
independently read/write their own Codable JSON file under
`~/Library/Application Support/Filemator/` (`rules.json`,
`watchedFolders.json`, `history.json`). No shared persistence layer —
each store takes an injectable `fileURL` (defaulting to its real path) for
testability. There's no App Sandbox (not distributed via the App Store), so
folder access relies on `NSOpenPanel`-only selection (never typed paths)
plus macOS's automatic one-time TCC prompts for Downloads/Desktop/Documents
— no security-scoped bookmark management.

**Testing split:** `RuleEngine` and `Mover` are pure/pure-ish functions unit
tested directly. `FolderWatcher` and store tests exercise real temp
directories rather than mocking the filesystem — match that pattern
(inject a `fileURL`/`folderURL` pointing at a temp dir) rather than
introducing mocks/protocols for `FileManager`.

## Code style

- SwiftLint enforced (`.swiftlint.yml`): 130-char line length warning /
  200-char error, opt-in `empty_count`, `explicit_init`, `closure_spacing`.
- No comments explaining error-handling rationale unless genuinely
  non-obvious (see `LoginItemManager.isEnabled` setter for the one existing
  example — explains why a registration failure is swallowed rather than
  surfaced).
