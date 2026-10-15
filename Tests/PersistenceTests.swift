import Foundation
import SwiftData

@main struct PersistenceTests {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Lift-test-\(UUID().uuidString).store")
        let schema = Schema([TrainingSplit.self, Routine.self, Workout.self, LiftSet.self])
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        var routineID: UUID!
        var workoutID: UUID!
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container); context.autosaveEnabled = false
            try Persistence.seed(context); try Persistence.seed(context)
            let splitCount = try context.fetchCount(FetchDescriptor<TrainingSplit>()); precondition(splitCount == 1)
            let routineCount = try context.fetchCount(FetchDescriptor<Routine>()); precondition(routineCount == 4)
            let routine = try context.fetch(FetchDescriptor<Routine>()).first { $0.name == "Upper" }!
            routineID = routine.id
            let session = Workout(routine: routine, splitName: "Upper / Lower", equipment: "Thea gym")
            workoutID = session.id; context.insert(session)
            let set = LiftSet(workoutID: session.id, exerciseID: "seated-row", parsed: WeightParser.parse("45 kg x 8", defaultUnit: .lb)!, reps: 8, warmup: false, rawInput: "45 kg x 8")
            context.insert(set); try context.save()
            routine.name = "Renamed"; routine.exerciseIDs = ["bench"]; routine.archived = true
            try context.save()
            precondition(session.routineName == "Upper" && session.exerciseIDs.first == "seated-row", "session snapshots must not change")
        }
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let session = try context.fetch(FetchDescriptor<Workout>()).first!
            let set = try context.fetch(FetchDescriptor<LiftSet>()).first!
            precondition(session.id == workoutID && session.routineID == routineID && session.finishedAt == nil, "active workout recovers")
            precondition(set.kilograms == 45 && set.reps == 8 && set.unit == "kg", "sets survive reopening")
            session.finishedAt = .now; try context.save()
            let routine = try context.fetch(FetchDescriptor<Routine>()).first { $0.id == routineID }!
            precondition(routine.archived && session.routineName == "Upper", "archiving retains history")
        }
        print("Passed persistence checks: idempotent seeding, snapshots, disk reopen, active recovery, archive history")
    }
}
