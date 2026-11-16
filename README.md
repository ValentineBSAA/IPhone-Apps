# iPhone Apps

This repository hosts experiments in genuinely native iPhone apps. No websites or PWAs.

## Repo Pulse iOS · Pocket Premium v1.3.0

Native SwiftUI dashboard for public GitHub repositories, with a premium teal/navy home dashboard, richer release cards, a custom reproducible app icon, and detailed release history. No subscription, backend, API key, or third-party dependencies.

- Watch repositories and inspect GitHub stars, forks and open issues.
- Show download totals from GitHub release assets and the most recent release.
- Native release chart showing up to ten recent releases.
- Add and remove public repositories; track four repositories per page.
- Manual refresh and pull-to-refresh. Your watchlist is stored locally.

### Counting and access limitations

The app requests the latest 100 releases per repository. It sums the assets' download_count fields, which are GitHub release-asset downloads, NOT unique users, Steam Deck installs or downloads from other services. Old releases beyond the first 100 are not included.

GitHub unauthenticated REST API calls are limited to roughly 60 requests per hour per originating IP. Each tracked repository needs two requests per refresh. No automatic background monitoring or push notifications are claimed.

### Build and install from Windows 11

1. Open GitHub Actions for this repository, select Repo Pulse iOS Build and run the workflow (or inspect the build from a pull request).
2. The macOS runner uses XcodeGen and Xcode to compile a real iOS app.
3. Download the RepoPulse-DECK-EDITION-v1.3.0-BUILD4 artifact, extract its ZIP, and obtain RepoPulse-DECK-EDITION-v1.3.0-BUILD4-UNSIGNED.ipa.
4. This IPA is unsigned. The project retains the bundle ID `com.valentinebsaa.repopulse` and declares version 1.3.0 (build 4). A compatible local sideloading tool must SIGN it before installation on your iPhone. Free Apple ID signing generally requires refreshing within seven days.

No Apple credentials are required in the build job. A green CI result proves compilation, NOT that signing, installation or physical-device behavior have passed testing.

For a Mac build: install Xcode and XcodeGen, run xcodegen generate, then build the RepoPulse scheme.

### Development checkpoints

- [x] Create the native project structure and CI recipe.
- [x] Confirm the original unsigned build succeeds in GitHub Actions.
- [ ] Confirm the Premium pass unsigned build succeeds in GitHub Actions.
- [x] Install and launch the original signed IPA on the physical iPhone.
- [ ] Install and verify the Premium update on physical iPhone.
- [ ] Compare release totals with GitHub and test a rate-limited response.
- [ ] Consider caching, downloads history, repository search, and secure optional sign-in.

ResonaDeck Pocket is a future separate application, not part of this first build.

### Installed build verification
The home screen now displays **POCKET PREMIUM EDITION — VERSION 1.2.0 • BUILD 3** in a purple/teal edition strip immediately below the header. It also shows a **RELEASE FOOTPRINT** comparison chart. If you still see **Your code, at a glance.**, the original build is running. Use the *new, version-named IPA* and sign with the same Apple developer team. Do not uninstall first if preserving the local watchlist matters.

## Repo Pulse native iPhone Deck Edition v1.3.0 (build 4)

Source reference: the user's Repo Pulse 0.8.3 Decky plugin ZIP. This is a native SwiftUI app with one permanently dark blue/cyan/violet look, never a light-theme toggle.

- Home: all watched projects in a four-tile, two-column dashboard with Deck versus Other classifications, per-project unread bell, newest tags, paging, asset and release filters.
- Analytics: category-separated leaderboard, gap to next rank, and momentum based only on comparable saved observations.
- Quick Glance and Deck Pulse Briefing with selected release/asset metrics and real saved growth.
- Trophies: all 35 Decky tiers, earned using primary-package download high-water marks, not inflated screenshot archives.
- Release comparison modes: All/Newest/Stable/Preview; Primary packages / All ZIPs / All files; beta-only Home fallback is explicitly labeled and beta-only repositories stay unranked in strict stable leaderboards.
- Native iPhone notifications: local banner/list delivery, optional default system sound, authorization control and test-alert button; new download, release, stars and trophy events are stored in the app inbox. The first refresh is baseline only, never imaginary growth.
- Actual Repo Pulse Decky cube icon artwork is bundled through macOS AppKit icon generation. The original iPhone bundle identifier and local watchlist storage key remain unchanged.

**Honest limitations:** This release fetches up to 100 releases per public GitHub repository, rather than Decky's paginated 2,000-release authenticated scan, and has no automatic push-notification server, full settings backup/restore or complete third-party project artwork discovery. iOS may suspend the app when closed. Therefore native alerts are created when an active refresh discovers real changes; guaranteed instant notifications with the app terminated would require APNs and a backend. GitHub REST unauthenticated quotas apply. Foreground polling is intentionally conservative at 15 minutes. Device verification still required.

### Visual fix v1.3.1 (build 5)
- Replaced the broken embedded JPEG/Base64 icon pipeline with deterministic native vector illustration. The real AppIcon PNG and the in-app RepoPulseMark PNG are independently generated and validated.
- Replaced duplicated app-brand thumbnail on every repository card with distinct SF Symbols, preserving the current colors and counts.
- Clipped scrolling content beneath the iOS status bar and shortened the truncated header subtitle.
- Existing native notification banners and sounds are unchanged.
- Output: **RepoPulse-DECK-EDITION-v1.3.1-BUILD5-VISUAL-FIX-UNSIGNED.ipa**; the same iOS bundle identifier is preserved.
