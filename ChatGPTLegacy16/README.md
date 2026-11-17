# Chat Companion for iOS 16

A small, personal iPhone app that opens the **real ChatGPT website** in a persistent WKWebView, targeted at an **iPhone 14 Pro on iOS 16.0**. Project version: **0.1.0 (experimental)**.

This is **unofficial**, is **not** an OpenAI app, and contains no API key or impersonated authentication. You sign into your own account on chatgpt.com.

## What it does
- iOS deployment target 16.0; native SwiftUI shell and WebKit browser.
- Existing ChatGPT web conversation history and web-supported features, subject to site compatibility.
- Back, refresh, Safari fallback, persistent WKWebView website data.
- WebKit file picker support via standard website input behavior, subject to website and OS support.
- Dark native header and status bar support.

## What it cannot promise
- It is **not** a rebuilt official ChatGPT iOS app. Native ChatGPT Voice, push notifications, full app integrations and all modern web features are **not guaranteed**.
- ChatGPT/identity-provider sign-in may reject embedded webviews. Use the **Safari** button when sign-in fails. Safari sign-in is **not automatically transferred** to the embedded WebKit session.
- Google OAuth generally disallows embedded WebKit sign-in. Logging in directly via email/password may work depending on ChatGPT's current login rules.
- No jailbreak is needed to compile it; a jailbroken phone's installation method is separate.
- A future ChatGPT website change may break webview compatibility, especially on iOS 16's older WebKit.
- The Codemagic/GitHub build is **unsigned**. Installing an unsigned IPA requires your own suitable signing or jailbreak installation mechanism. A jailbreak does not by itself guarantee every unsigned IPA installs.

## Build (Mac / CI)
```sh
brew install xcodegen
cd ChatGPTLegacy16
xcodegen generate --spec project.yml
xcodebuild -project ChatGPTLegacy16.xcodeproj -scheme ChatGPTLegacy16 -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
mkdir -p dist/Payload
cp -R build/Build/Products/Release-iphoneos/ChatGPTLegacy16.app dist/Payload/
(cd dist && zip -qr Chat-Companion-iOS16-v0.1.0-unsigned.ipa Payload)
```

### Automatic build
GitHub Actions > **Chat Companion iOS 16 unsigned IPA** > **Run workflow**. Download the artifact containing the unsigned IPA after the workflow completes. Builds need a macOS runner; the project cannot be compiled with native Apple iOS tooling on Windows alone.

## Privacy
The app loads https://chatgpt.com directly and uses the operating system's persistent WebKit website data store. It does not intercept passwords, copy sessions to a server, inject JavaScript, or use API keys. Never place access tokens in a public repo.

## Known testing gap
Source and CI workflow have been authored, but no physical iOS 16.0 iPhone 14 Pro or completed CI build has been verified here. Treat this as a first test build, not confirmed functional parity.
