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

Reviewed historical-notes import (mixed/unknown units and malformed sets need resolution), full JSON backup/restore, optional private iCloud sync, custom exercise definitions, and per-exercise target/rest overrides. No historical dates or weights have been invented or silently imported. The HTML mockups in `docs` are design references, separate from the native app.

## Current verification

- Debug iOS Simulator build succeeds for arm64 and x86_64 with signing disabled.
- 21 parser/catalog checks pass.
- On-disk SwiftData tests pass for catalog seeding, session snapshots, reopening storage, active workout recovery and preserved archive history.
- Simulator UI execution has not been verified: this Mac has no installed iOS simulator runtime. Install one in Xcode or run on a connected iPhone to exercise the native screens.
