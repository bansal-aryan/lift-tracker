import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportFile: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws { text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? "" }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data(text.utf8)) }
}
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var workouts: [Workout]
    @Query(sort: \LiftSet.createdAt) private var sets: [LiftSet]
    @AppStorage("entryUnit") private var entryUnit = "lb"
    @AppStorage("displayUnit") private var displayUnit = "lb"
    @AppStorage("equipment") private var equipment = "Thea gym"
    @AppStorage("restSeconds") private var restSeconds = 90
    @State private var exporting = false
    @State private var file = ExportFile(text: "")
    @State private var error: String?
    var body: some View {
        Form {
            Section("Units") {
                Picker("Entry default", selection: $entryUnit) { Text("Pounds").tag("lb"); Text("Kilograms").tag("kg") }
                Picker("Progress", selection: $displayUnit) { Text("Pounds").tag("lb"); Text("Kilograms").tag("kg") }
            }
            Section {
                TextField("Gym / equipment profile", text: $equipment)
            } header: { Text("Equipment") } footer: { Text("Use a different profile when changing machines. Progress stays separate for each profile.") }
            Section("Rest timer") { Stepper("\(restSeconds) seconds", value: $restSeconds, in: 15...600, step: 15) }
            Section {
                Button("Export workout data", systemImage: "square.and.arrow.up") { file = ExportFile(text: csv()); exporting = true }
            } footer: { Text("Data stays on this iPhone. CSV export includes logged sets; it is not a full app backup.") }
        }
        .scrollContentBackground(.hidden).background(Color.white).navigationTitle("Settings")
        .toolbar { Button("Done") { dismiss() } }
        .fileExporter(isPresented: $exporting, document: file, contentType: .commaSeparatedText, defaultFilename: "Lift-workouts") { result in
            if case .failure(let failure) = result { error = failure.localizedDescription }
        }
        .saveError($error)
    }
    private func csv() -> String {
        func quote(_ value: String) -> String {
            let safe = ["=", "+", "-", "@", "\t", "\r"].contains(where: value.hasPrefix) ? "'" + value : value
            return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        var rows = ["workout_id,routine_id,split,routine,date,completed,equipment,exercise,weight,unit,kilograms,reps,warmup,original_input,week_label,review_reason"]
        for set in sets {
            guard let workout = workouts.first(where: { $0.id == set.workoutID }) else { continue }
            rows.append([workout.id.uuidString, workout.routineID.uuidString, workout.splitName, workout.routineName, workout.startedAt?.ISO8601Format() ?? "", String(workout.isComplete), workout.equipment, Catalog.find(set.exerciseID).name, String(set.load), set.unit, String(set.kilograms), String(set.reps), String(set.warmup), set.rawInput, workout.historicalLabel ?? "", set.reviewReason].map(quote).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }
}
