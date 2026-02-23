# Speakboard

Speakboard is a macOS menu bar app that turns speech into text using a hold-to-talk workflow.

## Features

- Global hotkey flow: hold `Option`, speak, release to transcribe
- Offline-first transcription pipeline
- Menu bar utility app for quick dictation into any app

## Build

```bash
swift build -c release
./build-app.sh
```

## Signed Release Build

```bash
./build-signed.sh
```

This script expects local Developer ID signing setup.

## Website

Landing page and Netlify deploy assets are in `website/`.
