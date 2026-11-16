# iPhone Apps

This repository hosts experiments in genuinely native iPhone apps. No websites or PWAs.

## Repo Pulse iOS · Pocket Premium v1.1.0

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
3. Download the RepoPulse-unsigned-ipa artifact, extract its ZIP, and obtain RepoPulse-unsigned.ipa.
4. This IPA is unsigned. The project retains the bundle ID `com.valentinebsaa.repopulse` and declares version 1.1.0 (build 2). A compatible local sideloading tool must SIGN it before installation on your iPhone. Free Apple ID signing generally requires refreshing within seven days.

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
