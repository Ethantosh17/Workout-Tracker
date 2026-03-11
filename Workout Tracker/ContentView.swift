import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) var appState
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPhone: TabView

    private var iPhoneLayout: some View {
        @Bindable var appState = appState
        return ZStack(alignment: .bottom) {
            TabView {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "house.fill") }
                WorkoutHistoryView()
                    .tabItem { Label("History", systemImage: "clock.fill") }
                ExerciseLibraryView()
                    .tabItem { Label("Exercises", systemImage: "dumbbell.fill") }
                ProgressView()
                    .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                MoreView()
                    .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
            }
            .tint(.orange)

            // Floating active workout banner
            if appState.isWorkoutActive && !appState.showingActiveWorkout {
                ActiveWorkoutBanner()
                    .padding(.horizontal)
                    .padding(.bottom, 56)
                    .onTapGesture { appState.showingActiveWorkout = true }
            }
        }
        .fullScreenCover(isPresented: $appState.showingActiveWorkout) {
            if let vm = appState.activeWorkoutVM {
                ActiveWorkoutView(vm: vm)
            }
        }
    }

    // MARK: - iPad: NavigationSplitView

    private var iPadLayout: some View {
        @Bindable var appState = appState
        return NavigationSplitView {
            List {
                NavigationLink(destination: DashboardView()) {
                    Label("Dashboard", systemImage: "house.fill")
                }
                NavigationLink(destination: WorkoutHistoryView()) {
                    Label("History", systemImage: "clock.fill")
                }
                NavigationLink(destination: ExerciseLibraryView()) {
                    Label("Exercises", systemImage: "dumbbell.fill")
                }
                NavigationLink(destination: ProgressView()) {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                NavigationLink(destination: TemplatesView()) {
                    Label("Templates", systemImage: "doc.text.fill")
                }
                NavigationLink(destination: BodyTrackingView()) {
                    Label("Body Tracking", systemImage: "figure.walk")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("WorkoutTracker")
        } detail: {
            DashboardView()
        }
        .tint(.orange)
        .fullScreenCover(isPresented: $appState.showingActiveWorkout) {
            if let vm = appState.activeWorkoutVM {
                ActiveWorkoutView(vm: vm)
            }
        }
    }
}

// MARK: - Active Workout Banner

struct ActiveWorkoutBanner: View {
    @Environment(AppState.self) var appState

    var body: some View {
        HStack {
            Image(systemName: "dumbbell.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.activeWorkoutVM?.workout.name ?? "Active Workout")
                    .font(.headline)
                if let vm = appState.activeWorkoutVM {
                    Text(vm.elapsedFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.up")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8, y: 2)
    }
}

// MARK: - More Tab

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: TemplatesView()) {
                    Label("Templates", systemImage: "doc.text.fill")
                }
                NavigationLink(destination: BodyTrackingView()) {
                    Label("Body Tracking", systemImage: "figure.walk")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("More")
        }
    }
}
