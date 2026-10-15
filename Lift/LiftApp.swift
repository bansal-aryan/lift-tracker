import SwiftUI
import SwiftData

extension Color {
    static let liftPurple = Color(red: 0.46, green: 0.26, blue: 0.81)
    static let liftWash = Color(red: 0.96, green: 0.94, blue: 0.99)
}
@main struct LiftApp: App {
    private let storage: Result<ModelContainer, Error>
    init() {
        storage = Result {
            let schema = Schema([TrainingSplit.self, Routine.self, Workout.self, LiftSet.self])
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .none))
            container.mainContext.autosaveEnabled = false
            try Persistence.seed(container.mainContext)
            return container
        }
    }
    var body: some Scene {
        WindowGroup {
            switch storage {
            case .success(let container): RootView().modelContainer(container).tint(.liftPurple).preferredColorScheme(.light)
            case .failure(let error): ContentUnavailableView("Couldn’t open your data", systemImage: "externaldrive.badge.exclamationmark", description: Text(error.localizedDescription))
            }
        }
    }
}
struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { SplitsView() }.tabItem { Label("Splits", systemImage: "square.grid.2x2") }
            NavigationStack { ProgressHome() }.tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
            NavigationStack { ExerciseLibrary() }.tabItem { Label("Exercises", systemImage: "dumbbell") }
        }
    }
}
struct ErrorAlert: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View {
        content.alert("Couldn’t save", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) { message = nil }
        } message: { Text(message ?? "") }
    }
}
extension View { func saveError(_ error: Binding<String?>) -> some View { modifier(ErrorAlert(message: error)) } }
