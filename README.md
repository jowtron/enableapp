# EnableApp

A tiny macOS utility to fix the **"app is damaged and can't be opened"** error.

Drag any `.app` bundle onto the window and EnableApp runs `xattr -cr` on it to strip quarantine and damage attributes — no Terminal required.

![Drop zone screenshot placeholder](https://via.placeholder.com/420x200?text=Drop+.app+here)

## Usage

1. Download `EnableApp.zip` from [Releases](https://github.com/jowtron/enableapp/releases)
2. Unzip and open `EnableApp.app`
3. Drag the problematic `.app` onto the drop zone
4. A green checkmark confirms success — relaunch your app

> **First launch note:** EnableApp itself is unsigned, so macOS may block it too. Right-click → Open to bypass, or run once in Terminal:
> ```
> xattr -cr /path/to/EnableApp.app
> ```

## What it does

macOS Gatekeeper adds a `com.apple.quarantine` extended attribute to apps downloaded from the internet. Apps that weren't notarised by Apple can trigger the *"damaged and can't be opened"* message. Running:

```
xattr -cr /path/to/YourApp.app
```

removes all extended attributes recursively, clearing the quarantine flag and letting the app open normally.

## Build from source

Requires Swift (via Xcode Command Line Tools):

```bash
swiftc main.swift \
  -o EnableApp.app/Contents/MacOS/EnableApp \
  -framework AppKit \
  -framework SwiftUI \
  -framework UniformTypeIdentifiers
```

Then open `EnableApp.app`.

## Requirements

- macOS 13 Ventura or later
