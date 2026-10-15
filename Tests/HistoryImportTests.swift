import Foundation
import SwiftData

@main struct HistoryImportTests {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Lift-history-\(UUID().uuidString).store")
        let schema = Schema([TrainingSplit.self, Routine.self, Workout.self, LiftSet.self])
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        var count = 0
        func check(_ condition: Bool, _ label: String) { precondition(condition, label); count += 1 }
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            let context = ModelContext(container); context.autosaveEnabled = false
            try Persistence.seed(context); try HistoryImport.run(context)
            let sessions = try context.fetch(FetchDescriptor<Workout>())
            let sets = try context.fetch(FetchDescriptor<LiftSet>())
            check(HistorySource.rows.count == 122, "source exercise/week row count")
            check(sessions.count == 23, "21 ordinary week groups + duplicate and unknown week")
            check(sets.count == 306, "numeric set count")
            check(sessions.allSatisfy { $0.startedAt == nil && $0.finishedAt == nil && $0.isComplete }, "no invented dates or active sessions")
            check(Set(sessions.compactMap(\.importKey)).count == 23, "stable unique import keys")
            check(sets.filter { !$0.reviewReason.isEmpty }.count == 23, "flagged numeric entries excluded from analytics")
            let lowerWeek3 = sessions.first { $0.importKey == "thea-v1/Lower/3" }!
            let curls = sets.filter { $0.workoutID == lowerWeek3.id && $0.exerciseID == "hamstring-curl" }
            check(curls.contains { $0.load == 50 && $0.unit == "kg" && $0.kilograms == 50 }, "explicit kilograms retained")
            check(curls.filter { $0.load == 55 }.allSatisfy { $0.unit == "lb" && abs($0.kilograms - 24.94758035) < 0.000001 }, "unmarked weights are pounds after kg")
            check(sets.filter { $0.unit == "kg" }.count == 14, "explicit kilogram set count")
            check(sets.contains { $0.rawInput == "30x51" && $0.reps == 51 && !$0.reviewReason.isEmpty }, "51 preserved and flagged")
            check(sessions.contains { $0.importKey == "thea-v1/Upper/5-duplicate" && $0.historicalWeek == nil }, "duplicate not relabeled Week 6")
            check(sessions.contains { $0.importKey == "thea-v1/Lower 2/unknown" && $0.historicalWeek == nil }, "missing week not invented")
            check(sessions.contains { $0.importIssues.contains("12x PPP") }, "unreadable reps retained")
            check(sessions.contains { $0.importIssues.contains("‘90x’") }, "missing reps retained")
            check(sets.filter { $0.exerciseID == "preacher-curl" }.count == 4, "preacher variant distinct")
            check(sets.filter { $0.exerciseID == "single-leg-curl" }.count == 3, "single leg curl distinct")
            let changed = sets.first!; changed.reps = 99; try context.save()
            try HistoryImport.run(context)
            let after = try context.fetch(FetchDescriptor<LiftSet>())
            check(after.count == 306 && after.first(where: { $0.id == changed.id })?.reps == 99, "repeat import preserves edits and avoids duplicates")
        }
        do {
            let reopened = try ModelContainer(for: schema, configurations: config)
            let context = ModelContext(reopened)
            try HistoryImport.run(context)
            let sessions = try context.fetch(FetchDescriptor<Workout>())
            check(sessions.count == 23 && sessions.allSatisfy(\.isComplete), "reopening is idempotent")
        }
        print("Passed \(count) history import checks")
    }
}
