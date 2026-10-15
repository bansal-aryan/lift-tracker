# Lift — native iPhone app plan

## Product direction
A personal, offline workout journal optimized for logging between sets. Native Swift and SwiftUI; proposed minimum iOS 17 (confirm against your phone before implementation). No login, server, subscription, or shared users. SwiftData persists on-device; Swift Charts renders history. Start with local storage and JSON export/restore through Files; optional private iCloud sync is a later feature, not a dependency. A device-only database is not itself a backup.

Three tabs: Splits (home), Progress, Exercises. Home shows saved splits; opening a split shows its routines; opening a routine lets you start a workout or view that routine’s history. The four starter routines belong to an Upper / Lower split. Users can create additional splits and routines within them. Progress is grouped by routine, with exercise-level trends inside each routine. Settings lives in the navigation toolbar. Use a white and purple theme with minimal copy: omit motivational filler, redundant descriptions, and implementation notes from app screens. Retain functional labels, units, and actionable validation. Use system fonts, SF Symbols, semantic colors, Dynamic Type, VoiceOver labels, and 44-point minimum targets. Respect dark mode and Reduce Motion. The HTML prototype explores screen composition; actual controls will be native SwiftUI.

## Architecture
One Xcode application target plus unit/UI test targets, organized by feature. Avoid a backend and unnecessary packages.

SwiftUI screens → observable feature state → domain services → SwiftData store.

- Features/Workout: start/resume, set entry, rest timer, reorder/add/remove exercises, finish and edit history.
- Features/Routines: create any number of named routines from the exercise catalog; edit, duplicate and archive routines; ordered templates, target sets and rep ranges, exercise substitutions. Creation flow: New → name → select exercises → create. Persist custom routines alongside the four starter templates.
- Features/Progress: exercise trends, session history, personal records, filters.
- Features/Exercises: bundled catalog, aliases, search, custom exercises and equipment profiles.
- Domain: WeightParser, WorkoutService, ProgressCalculator, ImportReviewer. Pure value types and calculations where possible.
- Persistence: versioned SwiftData schema, explicit save boundaries, catalog seeding, migrations, export/import.

Use @Query for simple screen reads; isolate complex mutations in services, with main-actor model context for foreground writes. Long imports parse into value types off the UI thread, then commit through a controlled context. Do not pass live model instances across actors. No repository protocol per entity unless a concrete testing need emerges.

## Data model
All entities have stable UUIDs and timestamps; ordered children have explicit positions.

- ExerciseDefinition: stable catalog ID, name, aliases, muscle groups, equipment category, supported load semantics; built-in or custom. Archive referenced definitions instead of deleting historical identities.
- EquipmentProfile: exercise ID, gym/machine name, bilateral/unilateral variant, load convention (total barbell, per dumbbell, added plates, machine stack, assistance), optional side. Different machines/variants get separate comparison keys.
- Split: stable UUID, name, ordered routines. Archive splits without deleting workout history.
- Routine: parent split ID, name, notes, ordered RoutineExercise children. Names may repeat across splits; identity always uses UUID.
- RoutineExercise: exercise/profile reference, order, target set count, min/max reps, optional rest seconds. Planned sets are not completed sets.
- WorkoutSession: routine reference optional, snapshot name, start/end dates optional for legacy imports, source week label, status (active/completed), notes. An imported Week 1 is not assigned a fabricated calendar date.
- SessionExercise: exercise/profile reference plus name and convention snapshots, order, notes. A routine change must never rewrite a session.
- SetEntry: position, original input, entered numeric load/unit, canonical kilograms, reps, side, kind (warm-up/working), completion timestamp, optional RPE and notes. Assistance is a distinct load kind, not a negative ordinary weight. Unknown values stay null.
- ImportBatch / ImportIssue: raw source, parser version, source location, proposed interpretation, ambiguity status and user resolution. Repeated imports use batch fingerprints and row identities to prevent duplicates.
- Preferences: default display unit, default entry unit, optional gym, timer preferences. Simple preferences can use UserDefaults.

Session owns session exercises and sets (cascade); deleting routines does not delete sessions. Explicit save after adding/completing/editing sets, plus recovery of active sessions after termination. Failed writes retain entry text and show retry instead of falsely marking a set saved. Timer stores a target end time so backgrounding does not lose elapsed time.

## Weight entry
Support `135 lbs`, `45 kg`, `135x8`, `50kg x 10`, and `45 kg for 8 reps`. A weight-only value fills weight and leaves reps to the separate field. Decimal weights and lb/lbs/pound/pounds/kg/kilogram/kilograms aliases are accepted. This is a small deterministic parser, not an LLM or paid API. A future free-form multi-exercise note importer is separate.

Preview: `45 kg × 8 reps · 99.2 lb`. User explicitly saves. Missing units use the visibly selected entry unit for NEW input; historical imports require review of scope. Changing display units never alters stored values. Retain original numeric value/unit and use exactly 1 lb = 0.45359237 kg; round only for display. Use decimal-safe representation for entered values, normalized doubles for chart calculations. Reject negative loads and fractional/zero reps for completed lifting sets; permit zero added load when the exercise supports bodyweight. Unsupported text stays in the input with a useful explanation.

Do not silently interpret `50kgx11, 55x9` as all kilograms. Import UI can offer “apply kg to this exercise/week” with explicit confirmation. Set-level units always win. Resolve dumbbell load convention once per profile and show “each” in the logger.

## Progress that remains comparable
Progress first selects a split and routine, then shows that routine’s session history and exercise trends. Filter sessions by stable routine ID (never name), retaining routine/split name snapshots. Do not merge identical exercises from Upper and Upper 2 by default.

Default exercise graph within a routine: best completed working-set load per session for the same exercise, machine, side, and load convention, with reps attached to points. Also offer rep records at a selected weight, total completed reps, and recorded-load volume (sum of normalized load × reps). Label volume conventions; per-dumbbell volume is not silently doubled. Ignore incomplete/unreviewed sets and warm-ups by default.

Estimated 1RM is optional, clearly labeled estimate, using Epley weight × (1 + reps/30) for eligible ordinary resistance sets of 1–10 reps (1 rep uses actual load). Exclude assistance, unknown loads and unsuitable machine comparisons. Do not default to a single aggregate strength score. Assisted pull-up progress shows assistance and reps together: lower assistance is favorable only with comparable reps and equipment. Net load needs contemporaneous bodyweight and is deferred.

Historical charts use Week 1…6 until dates are supplied. Missing weeks remain gaps. Changing gyms/machines starts separate series. No claim of a record across unresolved equipment changes. The prototype's lat-pulldown chart shows your raw maximum recorded loads [115,115,121,120,120,130], assuming pounds for illustration; it is not yet a verified strength trend.

## Exercise catalog and your routines
Bundle versioned JSON in the app and seed by stable IDs; update definitions without duplicating or overwriting user customizations. Ship a curated common lifting catalog with searchable aliases, movement/muscle/equipment filters and custom additions. Avoid needing an external exercise API or licensed imagery for MVP.

Your four initial routine templates preserve these slots and order. Set/rep targets are editable proposals, not inferred prescriptions from historical notes.

- Upper: Seated Row; Lat Pulldown; Pec Deck; Dumbbell Shoulder Press; Lateral Raise (equipment unresolved); Overhead Triceps Extension (equipment unresolved); Barbell Curl, with Preacher Curl substitution.
- Lower: Hamstring Curl (machine type unresolved, single-leg variant supported); Barbell Back Squat; Hip Thrust (equipment unresolved); Leg Extension; Ab Crunch Machine.
- Upper 2: Incline Dumbbell Bench Press; Pec Deck; Assisted Pull-Up; Standing T-Bar Row; Dumbbell Lateral Raise; Incline Dumbbell Curl; Triceps Extension (variant/equipment unresolved).
- Lower 2: Lying Hamstring Curl (single-leg variant supported); Hack Squat; Barbell Romanian Deadlift; Bulgarian Split Squat; Leg Extension; Calf Extension (machine type unresolved); Ab Crunch (machine/free variant unresolved).

Aliases explicitly include Seated Row, DB Shoulder Press, Lat Raise, OH Tricep, BB Curl, Preacher, Hamstring Curls, BB Squat, Leg Ext/Leg Ext., AB Crunch Machine, DB Incline Bench, Assisted Pull Up, DB Lateral Raise, Incline Curl, Tricep Extension, Lying Hamstring, BB RDL, Calf Ext and AB Crunch. Do not merge Lat Raise into DB Lateral Raise or AB Crunch into machine crunch until equipment is confirmed.

Additional starter exercises: flat barbell/dumbbell bench press, incline barbell bench, push-up, conventional/sumo deadlift, front/goblet squat, leg press, walking/reverse lunge, seated/standing calf raise, unassisted pull-up/chin-up, barbell/dumbbell row, overhead barbell press, cable fly, face pull, rear-delt fly, hammer curl, cable pushdown, dips and hanging knee raise. Bodyweight movements get rep-only/added-load/assistance modes as appropriate.

## Import your notes safely
The supplied notes are a seed source, not already-clean database rows. Stage an import preview grouped by routine/week; preserve the source verbatim and confirm unresolved items before using them in analytics.

Required review examples:
- Upper overhead triceps has two Week 5 labels: do not assume the second is Week 6.
- `30x51`: unusually high rep count; flag for review, never replace automatically.
- `12x PPP`, `90x`, trailing commas: incomplete reps remain drafts, excluded from statistics.
- Lower 2 Leg Extension `Week 130x12, 140x11`: week label is missing/malformed.
- `h`, `freed`, standalone `E`: preserve as source text and ask for interpretation where relevant.
- Mixed explicit/implicit units, including later sets after kg entries: offer scoped unit decisions.
- Preacher versus barbell curls, single-leg versus bilateral curls, and unusually changed assisted pull-up values: confirm variant/machine/assistance convention.
- Weeks have no calendar dates and missing weeks must not become zero workouts.

MVP supports manual entry first; a reviewed migration of these notes follows before relying on imported charts. The prototype does not import or persist your notes.

## Delivery sequence and acceptance checks
1. Foundation: app shell, catalog and schema; create/reopen database, idempotent catalog seeding, export/restore round-trip and migration fixture.
2. Workout loop: Upper/Lower templates, logger, unit parser, autosaved active session, finish/edit. Verify mixed-unit conversion, save failure, app termination/recovery, snapshot isolation and keyboard/Dynamic Type behavior on iPhone.
3. Progress: comparable-profile charts, records and history; fixture-test mixed units, assistance direction, warm-up exclusion, missing reps and missing weeks.
4. Notes migration: source preservation, review queue, duplicate prevention and atomic import. Manually compare imported rows to the source before committing.
5. Polish: routine editing, rest timer, accessibility, backup reminders; optional private iCloud sync only after restore/conflict behavior is designed.

Before implementation, settle phone/iOS support and whether optional private iCloud backup/sync is desired. Before historical import, settle default units, dates (if known), equipment differences and the flagged entries. These do not block reviewing the design.

## References
- Apple SwiftData ModelContainer: https://developer.apple.com/documentation/swiftdata/modelcontainer
- Apple persistence guide: https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches
- Apple Swift Charts: https://developer.apple.com/documentation/charts
