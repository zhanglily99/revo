# Revo

**A little less.**

A tiny native macOS desktop companion that turns letting go of files into a small, tactile ritual. Drop a file into the slot and watch it become paper scraps. The real file moves to macOS Trash and remains recoverable.

<p align="center">
  <img src="docs/images/feeding.png" alt="Revo feeding a photo through its cream-colored lid into a pale green body" width="360">
</p>

## The little machine

Cream enamel, pale green paint, a polished metal rim, smoke glass, and one orange button. The machine is drawn in code with AppKit. Core Animation handles the paper feed, cutting, falling scraps, and subtle mechanical feedback.

- Documents become narrow paper strips.
- Photos use a thumbnail and break into confetti.
- Audio becomes a printed waveform.
- Video becomes perforated film strips.
- Folders feed a stack of sheets.
- Files larger than 200 MB feed more slowly.

No dependencies, accounts, network calls, or analytics.

## Use Revo

Open `build/Revo.app`. Revo appears near the bottom-right corner of your desktop.

| Gesture | Action |
| --- | --- |
| Drop one or more files | Move them to Trash and play the animation after success |
| Drag the machine body | Reposition it; the location is remembered |
| Press the orange button | Try a paper demo without moving any files |
| Right-click → Try It | Preview the document, photo, audio, video, or folder animation |
| Right-click → Undo Last File | Restore the most recently recycled file during this session |
| Right-click → Clear Paper Scraps | Clear the visual scraps inside the machine |
| Menu bar → Show Revo | Bring back the hidden machine |
| Menu bar → Sound | Toggle mechanical sound effects |

Undo refuses to overwrite a file that already occupies the original location. Files can also be recovered through Finder's Trash. Revo has no permanent-delete or empty-Trash action.

A folder is recycled as one item. Its three animated sheets are a visual treatment, rather than a count of its contents. Duplicate URLs and parent/child paths dropped together are filtered before processing.

Revo respects the system's Reduce Motion setting. At rest, there are no repeating animations or polling timers. The visible paper pile is capped at 90 fragments.

## Build

Requires macOS 14 or later and the Swift toolchain. Xcode Command Line Tools are sufficient.

```sh
git clone https://github.com/zhanglily99/revo.git
cd revo
./scripts/build-app.sh
open build/Revo.app
```

The script builds the executable, generates the app icon, packages `Revo.app`, and applies a local ad-hoc signature. Distribution signing and notarization are not configured.

To build just the executable:

```sh
swift build -c release --product Revo
```

## Verify and preview

```sh
.build/release/Revo --self-test
.build/release/Revo --preview "$PWD/build/preview"
```

The self-test creates disposable temporary fixtures and checks file classification, recycling, restoration, same-name conflict protection, and failure for a missing source file. It never uses existing user files.

Preview mode renders idle, feeding, and finished screenshots using demo sheets. It does not recycle any files.

## Inside the app

| File | Responsibility |
| --- | --- |
| `AppDelegate.swift` | App lifecycle and menu bar |
| `RevoPanel.swift` | Transparent floating panel and saved position |
| `RevoView.swift` | Drag and drop, animation queue, menus, and feedback |
| `MachineArtwork.swift` | Layered enamel body, glass, and mechanical button |
| `PaperSprite.swift` | File-specific paper previews and bounded photo thumbnails |
| `TrashService.swift` | System Trash operations and conflict-safe undo |
| `ShredStyle.swift` | File classification |
| `SoundSynth.swift` | Synthesized mechanical audio |
| `Stats.swift` | Local daily count |
| `SelfTest.swift` | Disposable file-operation checks |
| `Preview.swift` | Screenshot and icon export |

## Inspiration

[Tendedero](https://github.com/alejandrobujan/tendedero) inspired the small native-app approach and gesture-first interaction. Revo uses its own code and artwork.
