# Lift

Native iPhone workout tracker built with SwiftUI, SwiftData and Swift Charts. iOS 17+. No account, backend, external dependencies or network requests.

## Run

1. Open `Lift.xcodeproj` in Xcode.
2. Select the **Lift** scheme and an iPhone simulator, or connect your iPhone.
3. For a physical iPhone, choose your Apple development team under Signing & Capabilities and use a unique bundle identifier if necessary.
4. Run. Xcode may first need an iOS simulator runtime under Settings → Components.

## Included

- White and purple UI: Splits → Routines → Workout.
- Create/rename splits; create, edit, reorder exercises, duplicate and archive routines.
- Four starter routines and 42 built-in exercises, covering the supplied notes and distinct exercise variants.
- Per-routine set/rep targets; workouts snapshot these and exercise order.
- Parse `135 lbs`, `45 kg`, `50kgx10`, `45 kg for 8 reps`; a weight alone uses the separate reps field.
- Log, edit and delete sets, mark warm-ups, show previous sets, rest timer, resume active workout after relaunch.
- Routine-specific history and load/reps/recorded-volume charts; separate equipment profiles, original units retained, configurable chart units.
- Assisted pull-up charts use assistance weight; dumbbell weights are per hand.
- Local persistent store and CSV export of logged sets through Files.

Only one workout can be active. Starting another routine resumes the existing workout; finish or discard it first. Equipment profile is set in Settings before starting a workout. Use a different profile for different machines to keep trends comparable.

Archived routines remain available in Progress. History screens allow editing sets. CSV export is a data extract, not a restorable backup.

## Validation

`./scripts/test-domain.sh` runs parser/catalog checks with the Swift compiler.
`./scripts/test-persistence.sh` checks real on-disk SwiftData persistence, idempotent seeding, workout recovery, history snapshots and archiving on macOS 14+ (Apple Silicon).

Build without signing:

```sh
xcodebuild -project Lift.xcodeproj -scheme Lift -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/LiftDerived CODE_SIGNING_ALLOWED=NO build
```

## Still planned

Full JSON backup/restore, optional private iCloud sync, custom exercise definitions, and per-exercise target/rest overrides. Historical notes are now bundled and imported once, following your confirmed unit rule. No workout dates have been invented. The HTML mockups in `docs` are design references, separate from the native app.

## Base-app verification (before history import)

- Debug iOS Simulator build succeeds for arm64 and x86_64 with signing disabled.
- 21 parser/catalog checks pass.
- On-disk SwiftData tests pass for catalog seeding, session snapshots, reopening storage, active workout recovery and preserved archive history.
- Simulator UI execution has not been verified: this Mac has no installed iOS simulator runtime. Install one in Xcode or run on a connected iPhone to exercise the native screens.


## Your imported history

The app imports your Thea notes automatically on its next launch, including on a fresh iPhone install. Existing workouts are preserved. Stable import keys prevent repeat imports from duplicating or overwriting imported workouts and edits.

- 122 exercise/week source rows; 306 numeric sets across 23 history groups.
- 21 normal routine/week groups, one duplicate Week 5 group and one unknown-week group.
- Every unmarked weight is **lb**, even when the preceding set explicitly says kg. The 14 explicitly marked kg sets retain kilograms.
- Calendar dates remain nil; imported charts use week numbers and are separate from dated workouts.
- 23 numeric sets are flagged and excluded from charts: assistance/machine ambiguity, duplicate/missing week, unclear h/freed markers, and `30x51`.
- `12x PPP` and `90x` stay in Import notes, without invented reps. Empty trailing commas do not create sets.
- Preacher and explicitly single-leg curls remain distinct variants.

Open **Progress → routine → History** to see imported workouts. Each imported workout has **Original entries** and **Import notes**. Tap a flagged set to correct/confirm it; confirming enables that set for charts when a known week is available. Duplicate and unknown week groups remain outside charts until their week mapping is resolved; they are not silently reassigned. Imported equipment is marked unverified and stays separate from new workouts.

`./scripts/test-history.sh` passed 18 checks covering counts, mixed units, missing dates, review flags, variant mapping, disk reopen, duplicate prevention and preservation of edits. The updated iPhone hardware build was not run because its permission request was declined. The earlier base-app simulator build passed; this update still needs an Xcode build and device check.

## Installing on your iPhone

Downloading the source folder on the phone does not install an iOS app. Open the project on your Mac, connect/unlock the iPhone, select your signing team and the iPhone as the run destination, enable Developer Mode when required, then press Run in Xcode. Use iOS 17 or later. Keep the same bundle ID when updating to retain the existing app container; do not delete the app to update it.

After installation, Lift works offline and saves its data locally. A free Personal Team's provisioning expires after seven days, requiring rebuilding/reinstalling from Xcode. See Apple's account guidance: https://developer.apple.com/help/account/basics/about-your-developer-account . Data is not synced to iCloud; CSV export is not a full restorable backup. Native UI/device behavior has not yet been verified.
