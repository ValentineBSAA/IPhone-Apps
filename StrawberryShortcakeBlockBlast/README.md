# 🍓 Berry Block Blast for iPhone

**Version 0.1.0 | Native iPhone game | Self-contained project**

A strawberry-sweet, **unofficial fan concept** combining an original berry-garden character illustration with familiar 8×8 block puzzle mechanics. It is **not** endorsed by, affiliated with, or an official Strawberry Shortcake product or Block Blast product. No official character artwork, logos, audio, or game assets are copied.

## Features

- Fully native **SwiftUI iPhone app** (iOS 17 and later, portrait-first).
- 8×8 puzzle board with three draggable pieces per round.
- Drag preview, placement checks, simultaneous row and column clears.
- Combo streaks, bonus points, local high score, haptic feedback.
- Automatic local save and restore of your unfinished board.
- Original illustrated berry-hat mascot, pastel confectionery theme, and **unique app icon**.
- Offline only. No ads, login, tracking, external APIs, or in-app purchases.
- XcodeGen project generation, basic engine unit tests, and GitHub Actions for an unsigned device IPA.

## Generate and run on a Mac

1. Install Xcode, `brew install xcodegen`, and Python 3 with Pillow (`python3 -m pip install pillow`).
2. From this folder, run `python3 Tools/generate_icon.py` to create the 1024×1024 icon.
3. Run `xcodegen generate --spec project.yml`.
4. Open `BerryBlockBlast.xcodeproj`, choose the `BerryBlockBlast` scheme, and run on an iPhone or simulator.

Bundle ID: `com.valentinebsaa.berryblockblast`, deliberately separate from Repo Pulse and other iPhone apps.

## GitHub-built IPA

Open your repository's **Actions** tab and run **Berry Block Blast iPhone IPA** (`workflow_dispatch`). The workflow generates the unique icon, builds the iOS app with signing disabled, and uploads an artifact named `Berry-Block-Blast-v0.1.0-iPhone-unsigned` containing `Berry-Block-Blast-v0.1.0-unsigned.ipa`.

**Important:** An unsigned IPA cannot install on a normal iPhone by itself. Sideloadly, AltStore, or a similar tool must sign it with your Apple ID or a signing certificate. Free Apple ID signing generally expires after seven days; creating an IPA does not remove Apple's signing restriction. This GitHub workflow has not been verified on an actual Mac/iPhone in this environment.

## Copyright and artwork

This is a fan-made prototype, not a commercial licensed Strawberry Shortcake product. Its mascot and icon are **original illustrations** inspired by berry-garden cartoon aesthetics, not official character images or trademarks. If you want to publish a game with the official Strawberry Shortcake name or likeness, obtain authorization for those rights. The original mascot drawing lives in `BerryGirlView.swift`, and the icon generator is `Tools/generate_icon.py`.

## Gameplay rules

You get three block shapes. Drag a shape onto empty squares in the 8×8 board. Completing a row or column clears it and gives a sweet score bonus. Clearing more than one line at once earns extra points, and consecutive line-clearing moves build a streak. After you use all three pieces, the next set appears. The run ends when none of your available pieces can fit anywhere.

## Status

Prototype v0.1.0: model code passes local Swift syntax/type checks and the included icon is generated locally. Actual iOS compilation and iPhone touch testing still depend on macOS/Xcode and the GitHub Actions run. Keep this distinction clear before calling it device-tested.
