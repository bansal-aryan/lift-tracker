import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let workout: Workout
    @Query(sort: \LiftSet.createdAt) private var allSets: [LiftSet]
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @State private var exerciseID = ""
    @State private var input = ""
    @State private var reps = ""
    @State private var warmup = false
    @State private var confirmEntry = false
    @State private var error: String?
    @State private var editing: LiftSet?
    @State private var finish = false
    @State private var discard = false
    @AppStorage("entryUnit") private var entryUnit = "lb"
    @AppStorage("restEnd") private var restEnd = 0.0
    @AppStorage("restSeconds") private var restSeconds = 90
    @FocusState private var inputFocused: Bool
    var exercise: Exercise { Catalog.find(exerciseID) }
    var unit: WeightUnit { WeightUnit(rawValue: entryUnit) ?? .lb }
    var parsed: ParsedSet? { WeightParser.parse(input, defaultUnit: unit) }
    var resolvedReps: Int? { parsed?.reps ?? Int(reps) }
    var valid: Bool { parsed != nil && (resolvedReps ?? 0) > 0 && (resolvedReps ?? 0) <= 10_000 }
    var sets: [LiftSet] { allSets.filter { $0.workoutID == workout.id && $0.exerciseID == exerciseID } }
    var previous: [LiftSet] {
        let candidates = workouts.filter { candidate in
            guard candidate.id != workout.id, candidate.routineID == workout.routineID,
                  candidate.isComplete, candidate.equipment == workout.equipment else { return false }
            if let date = workout.startedAt, let priorDate = candidate.startedAt { return priorDate < date }
            if let week = workout.historicalWeek, let priorWeek = candidate.historicalWeek { return priorWeek < week }
            return false
        }.sorted { ($0.historicalWeek ?? 0) > ($1.historicalWeek ?? 0) }
        for candidate in candidates {
            let records = allSets.filter { $0.workoutID == candidate.id && $0.exerciseID == exerciseID && $0.reviewReason.isEmpty }
            if !records.isEmpty { return records }
        }
        return []
    }
    var body: some View {
        List {
            exerciseSection
            setSection
            entrySection
            restSection
            if workout.importKey != nil {
                Section(workout.dateLabel) {
                    if !workout.importIssues.isEmpty { DisclosureGroup("Import notes") { Text(workout.importIssues).font(.footnote) } }
                    DisclosureGroup("Original entries") { Text(workout.sourceNotes).font(.footnote).textSelection(.enabled) }
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.white).navigationTitle(workout.routineName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { if !workout.isComplete { Button("Finish") { finish = true }.disabled(!allSets.contains { $0.workoutID == workout.id }) } }
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { inputFocused = false } }
        }
        .onAppear { if exerciseID.isEmpty { exerciseID = workout.exerciseIDs.first ?? "" } }
        .onChange(of: exerciseID) { _, _ in clear() }
        .confirmationDialog("Finish workout?", isPresented: $finish, titleVisibility: .visible) {
            Button("Finish workout") {
                workout.finishedAt = .now
                do { try context.save(); restEnd = 0; dismiss() } catch { context.rollback(); self.error = error.localizedDescription }
            }
        }
        .confirmationDialog("Discard this workout and its sets?", isPresented: $discard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                for set in allSets where set.workoutID == workout.id { context.delete(set) }
                context.delete(workout)
                do { try context.save(); restEnd = 0; dismiss() } catch { context.rollback(); self.error = error.localizedDescription }
            }
        }
        .saveError($error)
    }
    @ViewBuilder private var exerciseSection: some View {
            Section {
                Picker("Exercise", selection: $exerciseID) {
                    ForEach(workout.exerciseIDs, id: \.self) { id in Text(Catalog.find(id).name).tag(id) }
                }
                if workout.importKey == nil { Text("\(workout.targetSets) sets · \(workout.minReps)–\(workout.maxReps) reps").font(.caption).foregroundStyle(.secondary) }
                if !workout.equipment.isEmpty { Text(workout.equipment).font(.caption).foregroundStyle(.secondary) }
            }
            if !previous.isEmpty {
                Section("Last time") {
                    Text(previous.map { "\(number($0.load)) \($0.unit) × \($0.reps)" }.joined(separator: "  ·  ")).font(.subheadline)
                }
            }

    }
    @ViewBuilder private var setSection: some View {
            Section(exercise.loadLabel) {
                ForEach(sets) { set in
                    Button { edit(set) } label: {
                        LoggedSetRow(set: set)
                    }.swipeActions { Button("Delete", role: .destructive) { delete(set) } }
                }
            }


    }
    @ViewBuilder private var entrySection: some View {
            Section(editing == nil ? "Next set" : "Edit set") {
                Picker("Default unit", selection: $entryUnit) { Text("lb").tag("lb"); Text("kg").tag("kg") }.pickerStyle(.segmented)
                TextField("135 lbs or 45 kg × 8", text: $input).textInputAutocapitalization(.never).autocorrectionDisabled().focused($inputFocused)
                if parsed?.reps == nil { TextField("Reps", text: $reps).keyboardType(.numberPad) }
                if let parsed {
                    Text("\(number(parsed.load)) \(parsed.unit.rawValue)\(resolvedReps.map { " × \($0)" } ?? "") · \(number(parsed.unit == .kg ? parsed.load / 0.45359237 : parsed.kilograms)) \(parsed.unit == .kg ? "lb" : "kg")")
                        .font(.caption).foregroundStyle(Color.liftPurple)
                } else if !input.isEmpty { Text("Enter a weight, optionally followed by × reps.").font(.caption).foregroundStyle(.secondary) }
                Toggle("Warm-up", isOn: $warmup)
                if let editing, !editing.reviewReason.isEmpty {
                    Text(editing.reviewReason).font(.caption).foregroundStyle(.secondary)
                    Toggle("Confirm this entry", isOn: $confirmEntry)
                }
                Button(editing == nil ? "Log set" : "Save set") { log() }.font(.headline).disabled(!valid)
                if editing != nil { Button("Cancel edit") { clear() } }
            }

    }
    @ViewBuilder private var restSection: some View {
            if !workout.isComplete {
                Section("Rest") {
                    TimelineView(.periodic(from: .now, by: 1)) { time in
                        let remaining = max(0, Int(ceil(restEnd - time.date.timeIntervalSince1970)))
                        HStack {
                            Text(remaining > 0 ? "\(remaining / 60):\(String(format: "%02d", remaining % 60))" : "Ready").monospacedDigit()
                            Spacer()
                            Button("Restart") { restEnd = Date.now.timeIntervalSince1970 + Double(restSeconds) }
                            Button("Skip") { restEnd = 0 }
                        }
                    }
                }
                Section { Button("Discard workout", role: .destructive) { discard = true } }
            }
    }
    private func clear() { input = ""; reps = ""; warmup = false; editing = nil; confirmEntry = false }
    private func edit(_ set: LiftSet) { confirmEntry = false; editing = set; input = "\(set.load) \(set.unit) x \(set.reps)"; warmup = set.warmup }
    private func delete(_ set: LiftSet) {
        let editingID = editing?.id
        let deletedID = set.id
        context.delete(set)
        do { try context.save(); if editingID == deletedID { clear() } } catch { context.rollback(); self.error = error.localizedDescription }
    }
    private func log() {
        guard let parsed, let count = resolvedReps, valid else { return }
        if let editing {
            editing.load = parsed.load; editing.unit = parsed.unit.rawValue; editing.kilograms = parsed.kilograms
            editing.reps = count; editing.warmup = warmup; editing.rawInput = input
            if confirmEntry { editing.reviewReason = "" }
        } else { context.insert(LiftSet(workoutID: workout.id, exerciseID: exerciseID, parsed: parsed, reps: count, warmup: warmup, rawInput: input)) }
        do {
            try context.save(); clear(); inputFocused = false
            if !workout.isComplete { restEnd = Date.now.timeIntervalSince1970 + Double(restSeconds) }
        } catch { context.rollback(); self.error = error.localizedDescription }
    }
}

struct LoggedSetRow: View {
    let set: LiftSet
    var body: some View {
        HStack {
            Text(set.warmup ? "W" : "•").foregroundStyle(.secondary).frame(width: 30)
            Text("\(number(set.load)) \(set.unit)").foregroundStyle(.primary)
            Spacer()
            Text("\(set.reps) reps").foregroundStyle(.primary)
            Image(systemName: set.reviewReason.isEmpty ? "checkmark.circle.fill" : "exclamationmark.circle").foregroundStyle(Color.liftPurple).accessibilityLabel(set.reviewReason.isEmpty ? "Logged" : "Needs review")
        }.padding(.vertical, 6)
    }
}
