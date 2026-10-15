import SwiftUI
import SwiftData
import Charts

struct ProgressHome: View {
    @Query(sort: \TrainingSplit.createdAt) private var splits: [TrainingSplit]
    @Query(sort: \Routine.position) private var routines: [Routine]
    var body: some View {
        List {
            ForEach(splits) { split in
                Section(split.name) {
                    ForEach(routines.filter { $0.splitID == split.id }) { routine in
                        NavigationLink { RoutineProgress(routineID: routine.id, name: routine.name, splitName: split.name) } label: {
                            HStack { Text(routine.name); if routine.archived { Text("Archived").font(.caption).foregroundStyle(.secondary) } }
                        }
                    }
                }
            }
        }.scrollContentBackground(.hidden).background(Color.white).navigationTitle("Progress")
    }
}
struct ProgressPoint: Identifiable {
    let id: UUID
    let date: Date
    let value: Double
    let reps: Int
}
struct RoutineProgress: View {
    let routineID: UUID
    let name: String
    let splitName: String
    @Query(sort: \Workout.startedAt, order: .reverse) private var allWorkouts: [Workout]
    @Query private var allSets: [LiftSet]
    @State private var exerciseID = ""
    @State private var equipment = ""
    @State private var metric = "Load"
    @AppStorage("displayUnit") private var displayUnit = "lb"
    var unit: WeightUnit { WeightUnit(rawValue: displayUnit) ?? .lb }
    var workouts: [Workout] { allWorkouts.filter { $0.routineID == routineID && $0.finishedAt != nil } }
    var exerciseIDs: [String] { Array(Set(workouts.flatMap(\.exerciseIDs))).sorted { Catalog.find($0).name < Catalog.find($1).name } }
    var profiles: [String] { Array(Set(workouts.map(\.equipment))).sorted() }
    var points: [ProgressPoint] {
        workouts.filter { $0.equipment == equipment }.compactMap { workout in
            let sets = allSets.filter { $0.workoutID == workout.id && $0.exerciseID == exerciseID && !$0.warmup }
            guard !sets.isEmpty else { return nil }
            if metric == "Reps" { return .init(id: workout.id, date: workout.startedAt, value: Double(sets.reduce(0) { $0 + $1.reps }), reps: 0) }
            if metric == "Volume" { return .init(id: workout.id, date: workout.startedAt, value: sets.reduce(0) { $0 + unit.display($1.kilograms) * Double($1.reps) }, reps: 0) }
            let best = Catalog.find(exerciseID).assistance ? sets.min(by: { $0.kilograms < $1.kilograms }) : sets.max(by: { $0.kilograms < $1.kilograms })
            guard let best else { return nil }
            return .init(id: workout.id, date: workout.startedAt, value: unit.display(best.kilograms), reps: best.reps)
        }.sorted { $0.date < $1.date }
    }
    var axis: String { metric == "Reps" ? "Reps" : metric == "Volume" ? "\(displayUnit) × reps" : Catalog.find(exerciseID).assistance ? "Assistance (\(displayUnit))" : "Load (\(displayUnit))" }
    var body: some View {
        List {
            if workouts.isEmpty {
                ContentUnavailableView("No workouts yet", systemImage: "chart.xyaxis.line", description: Text("Complete a workout in this routine to see progress."))
            } else {
                Section {
                    Picker("Exercise", selection: $exerciseID) { ForEach(exerciseIDs, id: \.self) { Text(Catalog.find($0).name).tag($0) } }
                    Picker("Equipment", selection: $equipment) { ForEach(profiles, id: \.self) { Text($0.isEmpty ? "Unspecified" : $0).tag($0) } }
                    Picker("Metric", selection: $metric) {
                        Text(Catalog.find(exerciseID).assistance ? "Assistance" : "Top load").tag("Load")
                        Text("Reps").tag("Reps")
                        if !Catalog.find(exerciseID).assistance { Text("Volume").tag("Volume") }
                    }.pickerStyle(.segmented)
                }
                if !points.isEmpty {
                    Section(axis) {
                        Chart(points) { point in
                            LineMark(x: .value("Date", point.date), y: .value(axis, point.value)).foregroundStyle(Color.liftPurple)
                            PointMark(x: .value("Date", point.date), y: .value(axis, point.value)).foregroundStyle(Color.liftPurple)
                                .accessibilityLabel(point.date.formatted(date: .abbreviated, time: .omitted))
                                .accessibilityValue("\(number(point.value)) \(axis)\(point.reps > 0 ? ", \(point.reps) reps" : "")")
                        }.chartXAxisLabel("Date").chartYAxisLabel(axis).frame(height: 220).padding(.vertical)
                        if Catalog.find(exerciseID).assistance { Text("Lower assistance with comparable reps indicates progress.").font(.caption).foregroundStyle(.secondary) }
                        if Catalog.find(exerciseID).perHand { Text("Weights are per dumbbell.").font(.caption).foregroundStyle(.secondary) }
                        ForEach(points.suffix(3).reversed()) { point in
                            HStack {
                                Text(point.date, style: .date).font(.subheadline)
                                Spacer()
                                Text("\(number(point.value))\(point.reps > 0 ? " × \(point.reps)" : "")").monospacedDigit()
                            }
                        }
                    }
                }
                Section("History") {
                    ForEach(workouts) { workout in
                        NavigationLink { WorkoutView(workout: workout) } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(workout.startedAt, format: .dateTime.month().day().year().hour().minute())
                                Text("\(allSets.filter { $0.workoutID == workout.id }.count) sets · \(workout.equipment)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.white).navigationTitle(name)
        .onAppear { if exerciseID.isEmpty { exerciseID = exerciseIDs.first ?? "" }; if equipment.isEmpty { equipment = profiles.first ?? "" } }
        .onChange(of: exerciseID) { _, _ in if Catalog.find(exerciseID).assistance && metric == "Volume" { metric = "Load" } }
    }
}
