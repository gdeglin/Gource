# GourceUI — macOS GUI for Gource

A native SwiftUI application that provides a graphical interface for configuring and launching Gource.

## Requirements

- macOS 13.0+
- Xcode 15+
- Gource installed at `/usr/local/bin/gource` (built from source or via Homebrew)

## Building

```bash
cd contrib/macos-ui
xcodebuild -project GourceUI.xcodeproj -scheme GourceUI -configuration Release
```

Or open `GourceUI.xcodeproj` in Xcode and build with ⌘B.

## Features

All Gource command-line options exposed across six tabs:

- **Display** — Viewport resolution, fullscreen, DPI, camera mode, crop
- **Playback** — Speed, time scale, date ranges, looping, auto-skip
- **Appearance** — Background, bloom, fonts, colours, title, logo, captions
- **Elements** — Show/hide elements, user avatars, file settings, highlighting
- **Filters** — User/file regex filters, git branch, log format
- **Output** — PPM stream export, config file save/load

Live command preview panel shows the generated command as you adjust settings.

## Keyboard Shortcuts

- **⌘Enter** — Launch Gource
- **⌘.** — Stop Gource
