# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Compile
swiftc \
  Sources/AIAndon/main.swift \
  Sources/AIAndon/AppDelegate.swift \
  Sources/AIAndon/SessionMonitor.swift \
  Sources/AIAndon/StatusLightView.swift \
  Sources/AIAndon/StatusLightWindow.swift \
  Sources/AIAndon/MenuBarIcon.swift \
  -o AIAndon \
  -framework AppKit \
  -framework ServiceManagement

# Run (background)
nohup ./AIAndon > /dev/null 2>&1 &

# Package DMG
pkill -f './AIAndon' 2>/dev/null
rm -rf AIAndon.app AI-Andon.dmg
mkdir -p AIAndon.app/Contents/MacOS
cp AIAndon AIAndon.app/Contents/MacOS/
cp Sources/AIAndon/Info.plist AIAndon.app/Contents/
codesign --force --deep --sign - AIAndon.app
hdiutil create -volname "AI Andon" -srcfolder AIAndon.app -ov -format UDZO AI-Andon.dmg
```

No Xcode project — uses raw `swiftc` compilation. CI is in `.github/workflows/release.yml`.

## Architecture

Native Swift macOS menu bar app (no Electron, no Xcode). 6 source files under `Sources/AIAndon/`:

```
main.swift → AppDelegate → SessionMonitor (reads ~/.claude/sessions/*.json)
                         → MenuBarIcon (menu bar colored dot)
                         → StatusLightWindow → StatusLightView (floating N-light panel)
```

**Data flow**: 10fps timer in `AppDelegate.tick()` polls `SessionMonitor.updateState()` → returns `[SessionInfo]` array → passed to both `StatusLightWindow.updateSessions()` and `MenuBarIcon.updateState()` (via `SessionMonitor.aggregateState()`).

**Session detection**: Reads JSON files from `~/.claude/sessions/`, validates PID is alive via `kill(pid, 0)`, and confirms process is Claude via `proc_pidpath`. Only `kind=interactive` sessions shown (filters out `kind=bg` background agents).

**Click-to-focus**: `StatusLightView` handles `mouseDown`, gets session TTY via `/usr/sbin/lsof`, walks process tree via `/bin/ps` to find terminal app (iTerm2/Terminal.app/etc), then uses AppleScript with TTY matching to select the specific window.

## Key Design Decisions

- `LSUIElement: true` in Info.plist — no Dock icon, menu bar only
- Floating window uses `.borderless` + `.floating` level + `isMovableByWindowBackground`
- Blink animation at 0.5s interval (independent timers in MenuBarIcon and StatusLightView)
- `SessionInfo` uses `Equatable` for dirty-checking to avoid redundant redraws
- AppleScript runs on main thread (`DispatchQueue.main.async`) for reliable iTerm2/Terminal communication

## Release

Push to `release` branch triggers GitHub Actions → builds on macOS-12 → creates DMG → publishes GitHub Release with tag from `CFBundleShortVersionString` in Info.plist.
