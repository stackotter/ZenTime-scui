# ZenTime

A calm, minimal macOS app for timed exam practice. ZenTime tracks how long
you spend on each question against a per-question time budget, gently
signals when you go over, and exports a styled PDF report when you're done.

- Set up an exam: total time, number of questions, marks per question.
- Work through questions with a live per-question and overall timer.
- A soft ascending chime plays when time is up.
- Export a clean PDF report — with over-time questions highlighted — via
  the macOS save panel.

Built entirely with SwiftUI, AppKit, AVFoundation, and CoreGraphics — no
third-party dependencies. Requires macOS 13 (Ventura) or later.

## Download

Grab the latest `.dmg` from the [Releases page](https://github.com/PatpateePhangern/ZenTime/releases/latest).

1. Download `ZenTime-X.Y.Z.dmg`.
2. Open the `.dmg` and drag **ZenTime.app** into **Applications**.
3. Launch ZenTime from Applications (see below if macOS blocks it).

## macOS blocked this app ("unidentified developer")

ZenTime is distributed without an Apple Developer Program membership, so the
app is not code-signed with a Developer ID and is not notarized by Apple.
The build is still ad-hoc signed with macOS's Hardened Runtime enabled, but
on first launch Gatekeeper will still show a warning like:

> "ZenTime" can't be opened because Apple cannot check it for malicious software.

This only needs to be bypassed once. Pick any option below.

**Option A — Right-click to open (recommended)**
1. In Finder, go to Applications.
2. Right-click (or Control-click) **ZenTime.app** and choose **Open**.
3. In the dialog that appears, click **Open** again.
4. From then on, ZenTime opens normally by double-clicking.

**Option B — System Settings**
1. Try to open ZenTime normally (it will be blocked).
2. Go to **System Settings → Privacy & Security**.
3. Scroll to the Security section; you'll see a message about ZenTime being
   blocked. Click **Open Anyway**.
4. Confirm in the follow-up dialog.

**Option C — Terminal (fallback)**
If both of the above fail (e.g. Gatekeeper keeps refusing), clear the
quarantine attribute directly:
```bash
xattr -cr /Applications/ZenTime.app
```
Then open the app normally.

## Building from source

```bash
git clone https://github.com/PatpateePhangern/ZenTime.git
cd ZenTime
xcodebuild -project ZenTime.xcodeproj -scheme ZenTime \
  -configuration Release -derivedDataPath build \
  -destination 'platform=macOS' build
open build/Build/Products/Release/ZenTime.app
```

To regenerate the Xcode project after adding/removing source files, run
`python3 genproj.py` — do not hand-edit `ZenTime.xcodeproj/project.pbxproj`,
it is fully generated from that script.

## Releasing a new version

1. Bump `MARKETING_VERSION` (and optionally `CURRENT_PROJECT_VERSION`) in
   `genproj.py`.
2. Run `python3 genproj.py` to regenerate the project file.
3. Commit the changes.
4. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z` (tag must match
   `MARKETING_VERSION`).
5. The release workflow builds, packages, and publishes the `.dmg`
   automatically.

## License

MIT — see [LICENSE](LICENSE).
