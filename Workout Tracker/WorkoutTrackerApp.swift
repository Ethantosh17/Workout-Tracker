import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {
    let container: ModelContainer
    @State private var appState = AppState()

    init() {
        do {
            let schema = Schema([
                Exercise.self,
                Workout.self,
                WorkoutExercise.self,
                WorkoutSet.self,
                WorkoutTemplate.self,
                TemplateExercise.self,
                BodyEntry.self,
                PersonalRecord.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer creation failed: \(error)")
        }

        NotificationService.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(colorScheme(from: appState.theme))
                .onAppear {
                    SeedData.seedIfNeeded(context: container.mainContext)
                }
        }
        .modelContainer(container)
    }

    private func colorScheme(from theme: String) -> ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
