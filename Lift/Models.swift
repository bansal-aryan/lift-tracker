import Foundation
import SwiftData

@Model final class TrainingSplit {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var archived: Bool
    init(name: String) { id = UUID(); self.name = name; createdAt = .now; archived = false }
}
@Model final class Routine {
    @Attribute(.unique) var id: UUID
    var splitID: UUID
    var name: String
    var exerciseIDs: [String]
    var targetSets: Int
    var minReps: Int
    var maxReps: Int
    var position: Int
    var archived: Bool
    init(splitID: UUID, name: String, exercises: [String], position: Int = 0) {
        id = UUID(); self.splitID = splitID; self.name = name; exerciseIDs = exercises
        targetSets = 3; minReps = 8; maxReps = 12; self.position = position; archived = false
    }
}
@Model final class Workout {
    @Attribute(.unique) var id: UUID
    var routineID: UUID
    var splitName: String
    var routineName: String
    var exerciseIDs: [String]
    var startedAt: Date
    var finishedAt: Date?
    var equipment: String
    var targetSets: Int
    var minReps: Int
    var maxReps: Int
    init(routine: Routine, splitName: String, equipment: String) {
        id = UUID(); routineID = routine.id; self.splitName = splitName; routineName = routine.name
        exerciseIDs = routine.exerciseIDs; startedAt = .now; self.equipment = equipment
        targetSets = routine.targetSets; minReps = routine.minReps; maxReps = routine.maxReps
    }
}
@Model final class LiftSet {
    @Attribute(.unique) var id: UUID
    var workoutID: UUID
    var exerciseID: String
    var load: Double
    var unit: String
    var kilograms: Double
    var reps: Int
    var warmup: Bool
    var createdAt: Date
    var rawInput: String
    init(workoutID: UUID, exerciseID: String, parsed: ParsedSet, reps: Int, warmup: Bool, rawInput: String) {
        id = UUID(); self.workoutID = workoutID; self.exerciseID = exerciseID
        load = parsed.load; unit = parsed.unit.rawValue; kilograms = parsed.kilograms
        self.reps = reps; self.warmup = warmup; createdAt = .now; self.rawInput = rawInput
    }
}

@MainActor enum Persistence {
    static func save(_ context: ModelContext) throws { try context.save() }
    static func seed(_ context: ModelContext) throws {
        guard try context.fetchCount(FetchDescriptor<TrainingSplit>()) == 0 else { return }
        let split = TrainingSplit(name: "Upper / Lower"); context.insert(split)
        for (index, entry) in Catalog.starters.enumerated() {
            context.insert(Routine(splitID: split.id, name: entry.0, exercises: entry.1, position: index))
        }
        try context.save()
    }
}
