import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let muscle: String
    let equipment: String
    let aliases: String
    var assistance: Bool { id == "assisted-pull-up" }
    var perHand: Bool { equipment == "Dumbbell" }
    var loadLabel: String { assistance ? "Assistance" : perHand ? "Weight each" : "Weight" }
}

enum Catalog {
    static let all: [Exercise] = [
        .init(id: "seated-row", name: "Seated Row", muscle: "Back", equipment: "Machine", aliases: "cable row"),
        .init(id: "lat-pulldown", name: "Lat Pulldown", muscle: "Back", equipment: "Cable", aliases: "pulldown"),
        .init(id: "pec-deck", name: "Pec Deck", muscle: "Chest", equipment: "Machine", aliases: "fly"),
        .init(id: "db-shoulder-press", name: "Dumbbell Shoulder Press", muscle: "Shoulders", equipment: "Dumbbell", aliases: "DB shoulder press"),
        .init(id: "lateral-raise", name: "Lateral Raise", muscle: "Shoulders", equipment: "Unspecified", aliases: "lat raise"),
        .init(id: "overhead-triceps", name: "Overhead Triceps Extension", muscle: "Triceps", equipment: "Unspecified", aliases: "OH tricep"),
        .init(id: "barbell-curl", name: "Barbell Curl", muscle: "Biceps", equipment: "Barbell", aliases: "BB curl"),
        .init(id: "preacher-curl", name: "Preacher Curl", muscle: "Biceps", equipment: "Machine", aliases: "preacher"),
        .init(id: "hamstring-curl", name: "Hamstring Curl", muscle: "Legs", equipment: "Machine", aliases: "hamstring curls"),
        .init(id: "single-leg-curl", name: "Single-Leg Hamstring Curl", muscle: "Legs", equipment: "Machine", aliases: "unilateral curl"),
        .init(id: "barbell-squat", name: "Barbell Squat", muscle: "Legs", equipment: "Barbell", aliases: "BB squat back squat"),
        .init(id: "hip-thrust", name: "Hip Thrust", muscle: "Glutes", equipment: "Unspecified", aliases: "glute bridge"),
        .init(id: "leg-extension", name: "Leg Extension", muscle: "Legs", equipment: "Machine", aliases: "leg ext"),
        .init(id: "ab-machine", name: "Ab Crunch Machine", muscle: "Core", equipment: "Machine", aliases: "ab crunch machine"),
        .init(id: "incline-db-bench", name: "Incline Dumbbell Bench Press", muscle: "Chest", equipment: "Dumbbell", aliases: "DB incline bench"),
        .init(id: "assisted-pull-up", name: "Assisted Pull-Up", muscle: "Back", equipment: "Machine", aliases: "assisted pull up"),
        .init(id: "t-bar-row", name: "Standing T-Bar Row", muscle: "Back", equipment: "Plate loaded", aliases: "t bar row"),
        .init(id: "db-lateral-raise", name: "Dumbbell Lateral Raise", muscle: "Shoulders", equipment: "Dumbbell", aliases: "DB lateral raise"),
        .init(id: "incline-curl", name: "Incline Dumbbell Curl", muscle: "Biceps", equipment: "Dumbbell", aliases: "incline curl"),
        .init(id: "triceps-extension", name: "Triceps Extension", muscle: "Triceps", equipment: "Unspecified", aliases: "tricep extension"),
        .init(id: "lying-curl", name: "Lying Hamstring Curl", muscle: "Legs", equipment: "Machine", aliases: "lying hamstring"),
        .init(id: "single-leg-lying-curl", name: "Single-Leg Lying Curl", muscle: "Legs", equipment: "Machine", aliases: "lying hamstring single leg"),
        .init(id: "hack-squat", name: "Hack Squat", muscle: "Legs", equipment: "Machine", aliases: "hack squat"),
        .init(id: "rdl", name: "Barbell Romanian Deadlift", muscle: "Legs", equipment: "Barbell", aliases: "BB RDL"),
        .init(id: "bulgarian-split-squat", name: "Bulgarian Split Squat", muscle: "Legs", equipment: "Dumbbell", aliases: "Bulgarian split squats"),
        .init(id: "calf-extension", name: "Calf Extension", muscle: "Calves", equipment: "Machine", aliases: "calf ext"),
        .init(id: "ab-crunch", name: "Ab Crunch", muscle: "Core", equipment: "Unspecified", aliases: "crunch"),
        .init(id: "bench", name: "Barbell Bench Press", muscle: "Chest", equipment: "Barbell", aliases: "flat bench"),
        .init(id: "db-bench", name: "Dumbbell Bench Press", muscle: "Chest", equipment: "Dumbbell", aliases: "DB bench"),
        .init(id: "deadlift", name: "Deadlift", muscle: "Legs", equipment: "Barbell", aliases: "conventional deadlift"),
        .init(id: "sumo-deadlift", name: "Sumo Deadlift", muscle: "Legs", equipment: "Barbell", aliases: "sumo"),
        .init(id: "leg-press", name: "Leg Press", muscle: "Legs", equipment: "Machine", aliases: "leg press"),
        .init(id: "face-pull", name: "Face Pull", muscle: "Shoulders", equipment: "Cable", aliases: "rear delt"),
        .init(id: "hammer-curl", name: "Hammer Curl", muscle: "Biceps", equipment: "Dumbbell", aliases: "hammer"),
        .init(id: "pushdown", name: "Triceps Pushdown", muscle: "Triceps", equipment: "Cable", aliases: "rope pushdown"),
        .init(id: "goblet-squat", name: "Goblet Squat", muscle: "Legs", equipment: "Dumbbell", aliases: "goblet"),
        .init(id: "front-squat", name: "Front Squat", muscle: "Legs", equipment: "Barbell", aliases: "front squat"),
        .init(id: "barbell-row", name: "Barbell Row", muscle: "Back", equipment: "Barbell", aliases: "bent over row"),
        .init(id: "db-row", name: "Dumbbell Row", muscle: "Back", equipment: "Dumbbell", aliases: "DB row"),
        .init(id: "overhead-press", name: "Overhead Press", muscle: "Shoulders", equipment: "Barbell", aliases: "OHP military press"),
        .init(id: "calf-raise", name: "Standing Calf Raise", muscle: "Calves", equipment: "Machine", aliases: "calf raise"),
        .init(id: "cable-fly", name: "Cable Fly", muscle: "Chest", equipment: "Cable", aliases: "crossover")
    ]
    static func find(_ id: String) -> Exercise { all.first { $0.id == id } ?? .init(id: id, name: id, muscle: "Other", equipment: "Unspecified", aliases: "") }
    static let starters: [(String, [String])] = [
        ("Upper", ["seated-row", "lat-pulldown", "pec-deck", "db-shoulder-press", "lateral-raise", "overhead-triceps", "barbell-curl"]),
        ("Lower", ["hamstring-curl", "barbell-squat", "hip-thrust", "leg-extension", "ab-machine"]),
        ("Upper 2", ["incline-db-bench", "pec-deck", "assisted-pull-up", "t-bar-row", "db-lateral-raise", "incline-curl", "triceps-extension"]),
        ("Lower 2", ["lying-curl", "hack-squat", "rdl", "bulgarian-split-squat", "leg-extension", "calf-extension", "ab-crunch"])
    ]
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case lb, kg
    var id: String { rawValue }
    func kilograms(_ value: Double) -> Double { self == .lb ? value * 0.45359237 : value }
    func display(_ kg: Double) -> Double { self == .lb ? kg / 0.45359237 : kg }
}
struct ParsedSet: Equatable {
    let load: Double
    let unit: WeightUnit
    let reps: Int?
    var kilograms: Double { unit.kilograms(load) }
}
enum WeightParser {
    static func parse(_ text: String, defaultUnit: WeightUnit) -> ParsedSet? {
        let pattern = #"^\s*(\d+(?:\.\d+)?)\s*(lbs?|pounds?|kg|kilograms?)?\s*(?:(?:x|×|for)\s*(\d+)\s*(?:reps?)?)?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        func group(_ n: Int) -> String? { Range(match.range(at: n), in: text).map { String(text[$0]) } }
        guard let number = group(1), let load = Double(number), load.isFinite, load >= 0, load <= 100_000 else { return nil }
        let unitText = group(2)?.lowercased()
        let unit = unitText.map { $0.hasPrefix("k") ? WeightUnit.kg : .lb } ?? defaultUnit
        let reps = group(3).flatMap(Int.init)
        if group(3) != nil && (reps == nil || reps! < 1 || reps! > 10_000) { return nil }
        return .init(load: load, unit: unit, reps: reps)
    }
}
func number(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...2))) }
