import SwiftUI
import SwiftData

struct SplitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TrainingSplit.createdAt) private var splits: [TrainingSplit]
    @Query private var routines: [Routine]
    @Query private var workouts: [Workout]
    @State private var creating = false
    @State private var name = ""
    @State private var error: String?
    @State private var settings = false
    var body: some View {
        List {
            if let active = workouts.first(where: { $0.finishedAt == nil }) {
                Section {
                    NavigationLink { WorkoutView(workout: active) } label: {
                        Label("Resume \(active.routineName)", systemImage: "play.circle.fill").foregroundStyle(Color.liftPurple)
                    }
                }
            }
            Section {
                ForEach(splits.filter { !$0.archived }) { split in
                    NavigationLink { SplitView(split: split) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(split.name).font(.title3.bold())
                            Text("\(routines.filter { $0.splitID == split.id && !$0.archived }.count) routines").font(.subheadline).foregroundStyle(.secondary)
                        }.padding(.vertical, 12)
                    }.listRowBackground(Color.liftWash)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollContentBackground(.hidden).background(Color.white).navigationTitle("Splits")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button { settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings") }
            ToolbarItem(placement: .topBarTrailing) { Button("New", systemImage: "plus") { name = ""; creating = true } }
        }
        .alert("New split", isPresented: $creating) {
            TextField("Name", text: $name)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !clean.isEmpty else { return }
                context.insert(TrainingSplit(name: clean))
                do { try context.save() } catch { context.rollback(); self.error = error.localizedDescription }
            }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .sheet(isPresented: $settings) { NavigationStack { SettingsView() } }
        .saveError($error)
    }
}
struct SplitView: View {
    @Environment(\.modelContext) private var context
    let split: TrainingSplit
    @Query(sort: \Routine.position) private var routines: [Routine]
    @State private var create = false
    @State private var rename = false
    @State private var name = ""
    @State private var error: String?
    var body: some View {
        List {
            ForEach(routines.filter { $0.splitID == split.id && !$0.archived }) { routine in
                NavigationLink { RoutineView(routine: routine, splitName: split.name) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(routine.name).font(.headline)
                        Text("\(routine.exerciseIDs.count) exercises").font(.subheadline).foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                }
            }
            Button("New routine", systemImage: "plus") { create = true }
        }
        .scrollContentBackground(.hidden).background(Color.white).navigationTitle(split.name)
        .toolbar { Button("Rename", systemImage: "pencil") { name = split.name; rename = true } }
        .alert("Rename split", isPresented: $rename) {
            TextField("Name", text: $name)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                split.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                do { try context.save() } catch { context.rollback(); self.error = error.localizedDescription }
            }
        }
        .sheet(isPresented: $create) { NavigationStack { RoutineEditor(splitID: split.id, position: routines.count) } }
        .saveError($error)
    }
}
struct RoutineEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let splitID: UUID
    var position = 0
    var routine: Routine?
    @State private var name = ""
    @State private var selected: [String] = []
    @State private var sets = 3
    @State private var minReps = 8
    @State private var maxReps = 12
    @State private var picker = false
    @State private var error: String?
    var body: some View {
        Form {
            TextField("Routine name", text: $name)
            Section("Targets") {
                Stepper("\(sets) sets", value: $sets, in: 1...10)
                Stepper("\(minReps) minimum reps", value: $minReps, in: 1...50)
                Stepper("\(maxReps) maximum reps", value: $maxReps, in: minReps...100)
            }
            Section("Exercises") {
                ForEach(selected, id: \.self) { id in Text(Catalog.find(id).name) }
                    .onDelete { selected.remove(atOffsets: $0) }
                    .onMove { selected.move(fromOffsets: $0, toOffset: $1) }
                Button("Add exercises", systemImage: "plus") { picker = true }
            }
        }
        .scrollContentBackground(.hidden).background(Color.white).navigationTitle(routine == nil ? "New routine" : "Edit routine")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selected.isEmpty) }
        }
        .onAppear {
            if let routine { name = routine.name; selected = routine.exerciseIDs; sets = routine.targetSets; minReps = routine.minReps; maxReps = routine.maxReps }
        }
        .onChange(of: minReps) { _, value in if maxReps < value { maxReps = value } }
        .sheet(isPresented: $picker) { NavigationStack { ExercisePicker(selected: $selected) } }
        .saveError($error)
    }
    private func save() {
        let item = routine ?? Routine(splitID: splitID, name: name, exercises: selected, position: position)
        if routine == nil { context.insert(item) }
        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines); item.exerciseIDs = selected
        item.targetSets = sets; item.minReps = minReps; item.maxReps = maxReps
        do { try context.save(); dismiss() } catch { context.rollback(); self.error = error.localizedDescription }
    }
}
struct RoutineView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let routine: Routine
    let splitName: String
    @Query private var workouts: [Workout]
    @AppStorage("equipment") private var equipment = "Thea gym"
    @State private var edit = false
    @State private var active: Workout?
    @State private var error: String?
    @State private var archive = false
    var body: some View {
        List {
            Section {
                Button { start() } label: {
                    Label(workouts.contains { $0.finishedAt == nil } ? "Resume workout" : "Start workout", systemImage: "play.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(8)
                }.listRowBackground(Color.liftWash)
                NavigationLink { RoutineProgress(routineID: routine.id, name: routine.name, splitName: splitName) } label: { Label("Progress & history", systemImage: "chart.xyaxis.line") }
            }
            Section("Exercises") {
                ForEach(routine.exerciseIDs, id: \.self) { id in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Catalog.find(id).name)
                        Text("\(routine.targetSets) sets · \(routine.minReps)–\(routine.maxReps) reps").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.white).navigationTitle(routine.name)
        .toolbar {
            Menu {
                Button("Edit", systemImage: "pencil") { edit = true }
                Button("Duplicate", systemImage: "doc.on.doc") {
                    let copy = Routine(splitID: routine.splitID, name: routine.name + " copy", exercises: routine.exerciseIDs, position: routine.position + 1)
                    copy.targetSets = routine.targetSets; copy.minReps = routine.minReps; copy.maxReps = routine.maxReps
                    context.insert(copy)
                    do { try context.save() } catch { context.rollback(); self.error = error.localizedDescription }
                }
                Button("Archive", systemImage: "archivebox") { archive = true }
            } label: { Image(systemName: "ellipsis.circle") }
        }
        .confirmationDialog("Archive this routine? History will remain in Progress.", isPresented: $archive, titleVisibility: .visible) {
            Button("Archive routine") {
                routine.archived = true
                do { try context.save(); dismiss() } catch { context.rollback(); self.error = error.localizedDescription }
            }
        }
        .sheet(isPresented: $edit) { NavigationStack { RoutineEditor(splitID: routine.splitID, routine: routine) } }
        .navigationDestination(item: $active) { WorkoutView(workout: $0) }
        .saveError($error)
    }
    private func start() {
        if let existing = workouts.first(where: { $0.finishedAt == nil }) { active = existing; return }
        let session = Workout(routine: routine, splitName: splitName, equipment: equipment.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(session)
        do { try context.save(); active = session } catch { context.rollback(); self.error = error.localizedDescription }
    }
}
struct ExercisePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: [String]
    @State private var search = ""
    var body: some View {
        List(filtered) { exercise in
            Button {
                if selected.contains(exercise.id) { selected.removeAll { $0 == exercise.id } } else { selected.append(exercise.id) }
            } label: {
                HStack {
                    VStack(alignment: .leading) { Text(exercise.name).foregroundStyle(.primary); Text(exercise.muscle).font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    Image(systemName: selected.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                }
            }
        }
        .searchable(text: $search)
        .scrollContentBackground(.hidden).background(Color.white).navigationTitle("Exercises")
        .toolbar { Button("Done") { dismiss() } }
    }
    var filtered: [Exercise] { Catalog.all.filter { search.isEmpty || ($0.name + " " + $0.aliases + " " + $0.muscle).localizedCaseInsensitiveContains(search) } }
}
struct ExerciseLibrary: View {
    @State private var search = ""
    var body: some View {
        List(Catalog.all.filter { search.isEmpty || ($0.name + " " + $0.aliases + " " + $0.muscle).localizedCaseInsensitiveContains(search) }) { exercise in
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name)
                Text(exercise.muscle + " · " + exercise.equipment).font(.caption).foregroundStyle(.secondary)
                if exercise.assistance { Text("Log assistance weight").font(.caption).foregroundStyle(Color.liftPurple) }
                if exercise.perHand { Text("Log weight per dumbbell").font(.caption).foregroundStyle(Color.liftPurple) }
            }.padding(.vertical, 4)
        }.scrollContentBackground(.hidden).background(Color.white).navigationTitle("Exercises").searchable(text: $search)
    }
}
