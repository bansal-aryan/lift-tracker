import Foundation
import SwiftData

/// Transcribed from the user's supplied notes. Each row preserves its set text.
/// Unmarked weights are pounds, explicitly confirmed by the user.
enum HistorySource {
    static let text = """
Upper|seated-row|1|90x8, 100x8, 105x11
Upper|seated-row|2|100x10, 110x8, 110x11
Upper|seated-row|3|50kg x10, 70kg x 10, 70kgx7
Upper|seated-row|4|85x8, 85x8
Upper|seated-row|5|100x8, 100x7
Upper|seated-row|6|100x8, 100x6
Upper|lat-pulldown|1|100x8, 115x8, 115x5
Upper|lat-pulldown|2|115x7, 115x7, 115x8
Upper|lat-pulldown|3|110x8, 121x7, 121x7
Upper|lat-pulldown|4|100x10, 120x8, 120x7
Upper|lat-pulldown|5|110x10, 120x9, 120x6
Upper|lat-pulldown|6|120x10, 130x6, 130x5
Upper|pec-deck|1|70x12, 80x8, 80x10
Upper|pec-deck|2|80x10, 85x8, 90x8
Upper|pec-deck|3|88x10, 100x10, 111x8
Upper|pec-deck|4|90x10, 100x6, 100x9
Upper|pec-deck|5|110x6, 110x7
Upper|pec-deck|6|110x8, 110x6
Upper|db-shoulder-press|1|35x10, 40x8, 40x6
Upper|db-shoulder-press|2|40x8, 40x7, 40x7
Upper|db-shoulder-press|3|38.5x10, 44x5, 44x4
Upper|db-shoulder-press|4|35x9, 35x7
Upper|db-shoulder-press|5|40x8, 40x7, 40x7
Upper|db-shoulder-press|6|40x7, 49x7
Upper|lateral-raise|1|10x12, 10x10, 10x10
Upper|lateral-raise|2|10x10, 10x10, 10x7
Upper|lateral-raise|3|12x7, 12x7, 12x PPP
Upper|lateral-raise|4|10x13, 10x10,
Upper|lateral-raise|5|10x12, 10x12, 10x9
Upper|lateral-raise|6|10x10, 10x10, 10x8
Upper|overhead-triceps|1|30x9, 30x8, 30x51
Upper|overhead-triceps|2|30x8, 35x6, 30x8
Upper|overhead-triceps|3|33x10, 44x10, 44x10
Upper|overhead-triceps|4|30x12, 40x8
Upper|overhead-triceps|5|40x10, 50x8
Upper|overhead-triceps|5-duplicate|50x11, 60x7
Upper|barbell-curl|1|40x12, 40x12, 40x8
Upper|barbell-curl|2|50x8, 50x8, 50x5
Upper|preacher-curl|3|Preacher: 44x10, 55x7,
Upper|barbell-curl|4|40x10, 40x8
Upper|preacher-curl|5|Preacher: 40x12, 55x6
Upper|barbell-curl|6|55x10, 55x7
Lower|hamstring-curl|1|80x9, 90x10, 90x
Lower|hamstring-curl|2|90x8, 95x8, 95x8
Lower|hamstring-curl|3|50kgx11, 55x9, 55x8
Lower|single-leg-curl|4|Single Leg: 70x12, 70x11, 80x9
Lower|hamstring-curl|5|70x10, 80x11, 80x9
Lower|hamstring-curl|6|80x10, 80x12, 90x7
Lower|barbell-squat|1|95x8, 135x4, 135x3
Lower|barbell-squat|2|95x8, 135x4, 135x5
Lower|barbell-squat|3|40kgx8, 60x5, 60x5
Lower|barbell-squat|4|95x8, 135x3
Lower|barbell-squat|5|135x5, 145x3
Lower|barbell-squat|6|95x8, 145x4, 145x4
Lower|hip-thrust|1|80x10, 90x8, 90x9
Lower|hip-thrust|2|90x10, 100x10, 100x7
Lower|hip-thrust|3|20kgx8, 50x8, 50x7
Lower|hip-thrust|4|120x8, 120x6
Lower|hip-thrust|5|140x8, 140x8
Lower|hip-thrust|6|140x10, 140x9
Lower|leg-extension|2|120x10, 130x14
Lower|leg-extension|3|60kgx10, 65kgx10, 65kgx9
Lower|leg-extension|4|170x14, 190x8
Lower|leg-extension|5|190x10,
Lower|leg-extension|6|190x10, 190x10
Lower|ab-machine|2|100x11, 120x11,
Lower|ab-machine|3|50x9, 50x8
Lower|ab-machine|5|50x8, 50x6
Lower|ab-machine|6|55x8, 55x6
Upper 2|incline-db-bench|1|35x10, 40x10, 45x8
Upper 2|incline-db-bench|2|40x9, 45x10, 45x7
Upper 2|incline-db-bench|3|17.5kgx10, 22.5x6, 22.5x4
Upper 2|incline-db-bench|4|45x7, 45x8, 45x6
Upper 2|incline-db-bench|5|45x8, 45x8, 50x3
Upper 2|pec-deck|4|100x9, 120x5,
Upper 2|pec-deck|5|120x6, 120x5
Upper 2|assisted-pull-up|1|45x7, 45x8, 45x6
Upper 2|assisted-pull-up|2|45x8, 45x8, 45x6
Upper 2|assisted-pull-up|3|37.5x5, 37.5x5, 37.5x3
Upper 2|assisted-pull-up|4|100x8, 110x9
Upper 2|assisted-pull-up|5|100x10, 110x8, 110x7
Upper 2|t-bar-row|4|45x10, 50x8
Upper 2|t-bar-row|5|50x10, 50x7
Upper 2|db-lateral-raise|1|15x12, 15x12, 15x10
Upper 2|db-lateral-raise|2|15x15, 15x11, 15x7
Upper 2|db-lateral-raise|3|7.5kgx10, 7.5kgx10, 7.5x10
Upper 2|db-lateral-raise|4|15x12, 15x12
Upper 2|db-lateral-raise|5|17.5x12, 17.5x9
Upper 2|incline-curl|1|20x10, 20x6, 15x8
Upper 2|incline-curl|2|15x10, 15x6, 15x5
Upper 2|incline-curl|3|7.5kgx8, 7.5x8, 7.5x8
Upper 2|incline-curl|4|15x10, 15x8
Upper 2|incline-curl|5|17.5x7, 17.5x7
Upper 2|triceps-extension|1|60x7, 60x6, 60x5
Upper 2|triceps-extension|2|60x5, 55x5
Upper 2|triceps-extension|3|45kgx8, 45x8
Upper 2|triceps-extension|4|100x8, 100x7
Upper 2|triceps-extension|5|100x7, 100x6
Lower 2|lying-curl|1|80x10, 100x10, 110x8
Lower 2|lying-curl|2|100x10, 110x9, 112.5x8
Lower 2|single-leg-lying-curl|4|Single Leg: 70x12, 80x7
Lower 2|lying-curl|5|80x8, 80x9, 90x7
Lower 2|hack-squat|1|105x8, 155x8, 175x5, 175x6
Lower 2|hack-squat|2|105x8, 155x8, 180x5, 180x6
Lower 2|hack-squat|4|144x8, 164x10
Lower 2|hack-squat|5|144x8, 164x12,
Lower 2|rdl|1|135x8, 185x3, 185x3,
Lower 2|rdl|2|115x8, 165x5, 165x6
Lower 2|rdl|4|135x8, 145x8, 165x3
Lower 2|rdl|5|135x8, 135x8
Lower 2|bulgarian-split-squat|1|27.5x8, 27.5x10
Lower 2|bulgarian-split-squat|2|30x10
Lower 2|bulgarian-split-squat|4|25x10
Lower 2|leg-extension|1|120x8, 120x8
Lower 2|leg-extension|unknown|Week 130x12, 140x11,
Lower 2|leg-extension|4|170x8, 170x8
Lower 2|leg-extension|5|170x8, 170x9
Lower 2|calf-extension|1|h 80x8, 80x10
Lower 2|calf-extension|2|80x10, 80x10
Lower 2|ab-crunch|2|140x9, 130x9
Lower 2|ab-crunch|4|freed 60x8, 60x6
Lower 2|ab-crunch|5|50x9, 50x8
"""
    struct Row {
        let routine: String
        let exercise: String
        let week: String
        let raw: String
        var key: String { "thea-v1/\(routine)/\(week)" }
    }
    static var rows: [Row] {
        text.split(separator: "\n").map { line in
            let parts = line.split(separator: "|", maxSplits: 3).map(String.init)
            return Row(routine: parts[0], exercise: parts[1], week: parts[2], raw: parts[3])
        }
    }
}

@MainActor enum HistoryImport {
    static func run(_ context: ModelContext) throws {
        let existing = Set(try context.fetch(FetchDescriptor<Workout>()).compactMap(\.importKey))
        guard HistorySource.rows.contains(where: { !existing.contains($0.key) }) else { return }
        var routines = try context.fetch(FetchDescriptor<Routine>())
        let splits = try context.fetch(FetchDescriptor<TrainingSplit>())
        // Match the original split if available; do not attach to unrelated custom splits.
        let split = splits.first { $0.name == "Upper / Lower" } ?? TrainingSplit(name: "Thea history")
        if !splits.contains(where: { $0.id == split.id }) { context.insert(split) }
        var sessions: [String: Workout] = [:]
        for row in HistorySource.rows {
            if existing.contains(row.key) { continue }
            let routine: Routine
            if let found = routines.first(where: { $0.name == row.routine && $0.splitID == split.id }) { routine = found }
            else {
                let ids = Catalog.starters.first { $0.0 == row.routine }!.1
                routine = Routine(splitID: split.id, name: row.routine, exercises: ids, position: routines.count)
                context.insert(routine); routines.append(routine)
            }
            let workout: Workout
            if let found = sessions[row.key] { workout = found }
            else {
                workout = Workout(routine: routine, splitName: split.name, equipment: "Thea notes · equipment unverified")
                workout.startedAt = nil; workout.finishedAt = nil
                workout.importKey = row.key; workout.historicalWeek = Int(row.week)
                workout.historicalLabel = row.week == "unknown" ? "Week unknown" : row.week == "5-duplicate" ? "Week 5 · duplicate label" : "Week \(row.week)"
                workout.exerciseIDs = []
                context.insert(workout); sessions[row.key] = workout
            }
            if !workout.exerciseIDs.contains(row.exercise) { workout.exerciseIDs.append(row.exercise) }
            let exerciseName = Catalog.find(row.exercise).name
            workout.sourceNotes += "\(exerciseName): \(row.raw)\n"
            var cleaned = row.raw.replacingOccurrences(of: "Preacher: ", with: "").replacingOccurrences(of: "Single Leg: ", with: "")
            var rowIssue = ""
            if row.week == "5-duplicate" { rowIssue = "Duplicate Week 5 label; week needs confirmation." }
            if row.week == "unknown" { rowIssue = "Missing week number."; cleaned = cleaned.replacingOccurrences(of: "Week ", with: "") }
            if cleaned.hasPrefix("h ") { rowIssue = "Unclear ‘h’ prefix."; cleaned.removeFirst(2) }
            if cleaned.hasPrefix("freed ") { rowIssue = "Confirm ‘freed’ exercise/equipment variant."; cleaned.removeFirst(6) }
            if row.exercise == "assisted-pull-up" { rowIssue = "Confirm assistance convention and machine before comparing." }
            if !rowIssue.isEmpty { workout.importIssues += "\(exerciseName): \(rowIssue)\n" }
            for token in cleaned.split(separator: ",", omittingEmptySubsequences: false) {
                let raw = token.trimmingCharacters(in: .whitespaces)
                guard !raw.isEmpty else { continue } // trailing punctuation is not an invented set
                guard let parsed = WeightParser.parse(raw, defaultUnit: .lb), let reps = parsed.reps else {
                    workout.importIssues += "\(exerciseName): ‘\(raw)’ — missing or unclear reps.\n"; continue
                }
                let set = LiftSet(workoutID: workout.id, exerciseID: row.exercise, parsed: parsed, reps: reps, warmup: false, rawInput: raw)
                set.reviewReason = rowIssue
                if raw == "30x51" { set.reviewReason = "Confirm 51 reps; possible typo."; workout.importIssues += "\(exerciseName): ‘30x51’ — confirm reps.\n" }
                context.insert(set)
            }
        }
        // Preserve stray source tokens without interpreting them as workouts.
        if let first = sessions["thea-v1/Lower 2/2"] { first.sourceNotes += "Original heading: AB Crunch:h\n" }
        if let first = sessions["thea-v1/Upper 2/5"] { first.sourceNotes += "Standalone source token after Upper 2: E\n" }
        do { try context.save() } catch { context.rollback(); throw error }
    }
}
