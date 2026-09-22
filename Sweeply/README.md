# Sweeply — Smart Storage Cleaner for iOS

A production-ready iPhone storage cleaner built with **SwiftUI**, **Swift Concurrency**, **PhotoKit**, **Contacts**, and Apple's **Vision Framework**.

Sweeply implements the full **Scan $\rightarrow$ Review $\rightarrow$ Clean** loop designed to safely free up storage on iPhones running iOS 17+.

---

## 🌟 Key Features

### 1. Storage Dashboard
- **Real-time storage analytics**: Live gauge showing device storage capacity (Used vs Free GB) and estimated reclaimable space.
- **One-tap Smart Scan**: Concurrent categorization of similar photos, screenshots, large videos, and duplicate contacts.

### 2. Similar & Duplicate Photos Detection
- **High-Performance Multi-Stage Clustering**:
  - *Stage 1 (Temporal Pre-clustering)*: Filters candidates within tight timestamp windows to avoid quadratic $O(N^2)$ overhead on large libraries.
  - *Stage 2 (Vision Perceptual Hashing)*: Computes perceptual embeddings with `VNGenerateImageFeaturePrintRequest` and calculates feature print distance ($\le 0.45$).
  - *Stage 3 (Best Shot Selection)*: Automatically ranks the highest-quality photo in each cluster (based on resolution, sharpness heuristic, and favorite status) with a **⭐ BEST** badge, pre-selecting redundant duplicates for cleanup.

### 3. Screenshots Cleaner
- Automatically aggregates all screen captures using PhotoKit's `.photoScreenshot` media subtype.
- Batch multi-selection: "Select All", "Deselect All", and individual toggle.

### 4. Large Videos Manager & Compressor (Bonus)
- Lists all videos sorted strictly from largest to smallest with duration badges and exact file sizes.
- **Inline Video Player**: Instant preview before making decisions.
- **Video Compressor**: On-device video compression (`AVAssetExportSession`) with Low, Medium, and High quality presets showing before/after size comparisons (e.g., 437 MB $\rightarrow$ 35 MB).

### 5. Duplicate Contacts Finder & Merger
- Deep local scan using `CNContactStore`.
- Groups duplicate cards by:
  - Matching normalized phone numbers (handles international prefixes and formatting).
  - Matching normalized email addresses.
  - Matching full contact names.
- **Consolidated Merge**: Seamlessly merges multiple cards into a single enriched contact card with all numbers and emails preserved, safely removing redundant copies.

### 6. Review Before Delete & Safe Deletion Guarantee
- **Mandatory Safety Review Screen**: Displays an itemized list of every photo, video, and contact staged for deletion, showing total item count and exact storage freed.
- **Safety Net**: Deletions execute through `PHAssetChangeRequest.deleteAssets`, sending photos to Apple's native 30-day "Recently Deleted" album—preventing accidental permanent data loss.
- **Celebration Screen**: Confetti animation and storage reclaimed metrics upon successful cleanup.

### 7. Swipe to Clean (Bonus)
- Tinder-style interactive gesture deck for rapid photo curation:
  - Swipe **Right** $\rightarrow$ Keep photo.
  - Swipe **Left** $\rightarrow$ Mark for cleanup.
  - Undo button to revert accidental swipes.

### 8. Robust Permissions Handling
- First-class support for `authorized`, `limited` (iOS 14+ limited photo library selection with banner and picker presenter), and `denied` states (deep-linking directly to iOS Settings).

---

## 🛠️ Tech Stack & Architecture

- **Language & Framework**: Swift 5.0+ / Swift 6 compatible, SwiftUI, Combine.
- **Frameworks**: `Photos`, `PhotosUI`, `Vision`, `AVFoundation`, `AVKit`, `Contacts`, `CoreImage`.
- **Architecture**: MVVM with decoupled Services (`PhotoService`, `SimilarityService`, `ContactService`, `StorageService`, `VideoService`, `PermissionService`).
- **Privacy**: 100% On-Device execution. No data or media ever leaves the device.

---

## 🚀 How to Run

1. Open `Sweeply.xcodeproj` in Xcode (Xcode 15+).
2. Select your development team under the `Sweeply` target settings if deploying to a physical iPhone.
3. Select an iPhone running iOS 17.0+ (or an iOS 17+ Simulator) as the run destination.
4. Press **Cmd + R** to run.

### Running Unit Tests:
```bash
xcodebuild test -project Sweeply.xcodeproj -scheme Sweeply -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

---

## 📝 Submission Short Note (<150 words)

> **Tools used**: Xcode 16/Swift 6, SwiftUI, Swift Concurrency, PhotoKit, Contacts, Vision (`VNGenerateImageFeaturePrintRequest`), AVKit/AVFoundation.  
> **What works**: The full Scan $\rightarrow$ Review $\rightarrow$ Clean core loop: real-time storage dashboard; fast Vision-based similar photo detection with auto-best shot selection; screenshot batch cleaner; large video manager with playback and compression; duplicate contact detection, merge, and deletion; safe deletion (Recently Deleted preservation); robust permission states (full, limited, denied); and swipe-to-clean deck.  
> **What is missing**: Cloud sync and email unsubscribes (explicitly out of scope per brief).  
> **Hardest problem solved**: Scanning large photo libraries without UI stutter or memory spikes. Solved via a two-tier approach: rapid temporal and dimensional pre-clustering to prune candidate pairs from $O(N^2)$ to linear chunks, followed by downsampled Vision feature print extraction and distance thresholding on background concurrency queues.
