# WorkoutTracker

A full-featured iOS + iPadOS workout tracking app built with SwiftUI and SwiftData.

## Features

### Core Workout Tracking
- **Active Workout Logging** — Track exercises, sets, reps, and weight in real time
- **Set Types** — Normal, Warm-up, Drop Set, To Failure, AMRAP
- **Rest Timer** — Automatic rest timer after each completed set with customizable duration
- **Workout Timer** — Tracks session duration with pause/resume
- **Add/Remove/Reorder** exercises mid-workout
- **Plate Calculator** — Visual plate loading calculator with bar visualization

### Templates
- Create reusable workout templates with target sets, reps, and weights
- One-tap to start any template
- Track how many times each template has been used and when

### Exercise Library
- **100+ pre-loaded exercises** across Chest, Back, Shoulders, Arms, Legs, Core, Cardio, Full Body
- Filter by category, equipment
- Full search
- **Custom exercises** — add your own with muscle groups and instructions
- Per-exercise history showing previous performance for each set

### Progress & Analytics
- **Dashboard** with weekly stats, streak counter, quick-start buttons
- **Workout Frequency Chart** — weekly bar chart
- **Exercise Progress Charts** — estimated 1RM and session volume over time (Swift Charts)
- **Muscle Group Heatmap** — visual frequency map of muscles trained
- **Personal Records** — automatically tracked for max weight, est. 1RM, max reps, max volume
- **Lifetime Stats** — total workouts, volume, sets, average duration

### Body Tracking
- **Weight Log** with chart over time
- **BMI Calculator** (requires height in settings)
- **14 body measurements** — neck, shoulders, chest, biceps, forearms, waist, abdomen, hips, thighs, calves
- **Body fat percentage** and muscle mass tracking
- Measurement change tracking (before/after comparison)

### Workout History
- **Calendar View** — see workout days at a glance
- **Month-grouped list** with search
- Per-workout detail: duration, total volume, sets, reps, exercise breakdown

### Settings
- Weight unit: **lbs / kg**
- Measurement unit: **Imperial / Metric**
- Height (for BMI)
- Default rest timer duration with preset buttons
- Warmup/working set and rep defaults
- Daily workout reminder notification
- Light / Dark / System theme
- **Data export** — CSV export of all workouts, body entries, and PRs
- Clear all data

### Platform
- Universal: **iPhone + iPad**
- iPhone: TabView navigation
- iPad: NavigationSplitView sidebar

---

## Setup in Xcode

### Requirements
- Xcode 15.0+
- iOS 17.0+ / iPadOS 17.0+ deployment target
- Swift 5.9+

### Steps

1. **Open Xcode** → File → New → Project
2. Choose **iOS → App**
3. Set:
   - Product Name: `WorkoutTracker`
   - Team: Your team
   - Bundle Identifier: `com.yourname.workouttracker`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we use SwiftData manually)
4. Click **Next**, save to `~/WorkoutTracker/`

5. **Delete** the auto-generated `ContentView.swift` and `WorkoutTrackerApp.swift`

6. **Add files**: In the Xcode project navigator, right-click the `WorkoutTracker` group → Add Files to "WorkoutTracker"
   - Select all files/folders from `~/WorkoutTracker/WorkoutTracker/`
   - Make sure **"Copy items if needed"** is unchecked (files are already in place)
   - Make sure **"Add to target: WorkoutTracker"** is checked

7. **Add frameworks**: In project settings → Target → Frameworks, Libraries, and Embedded Content:
   - SwiftData (already included in iOS 17)
   - Charts (already included in iOS 16+)
   - UserNotifications (already included)

8. **Set deployment target**: Project settings → Target → General → Minimum Deployments → **iOS 17.0**

9. **Build & Run** (⌘R)

The app will seed 100+ exercises on first launch automatically.

### Folder Structure

```
WorkoutTracker/
├── WorkoutTrackerApp.swift          # App entry point, ModelContainer setup
├── ContentView.swift                # TabView (iPhone) / NavigationSplitView (iPad)
├── Models/
│   ├── Exercise.swift               # Exercise, ExerciseCategory, EquipmentType
│   ├── Workout.swift                # Workout, WorkoutExercise, WorkoutSet, SetType
│   ├── WorkoutTemplate.swift        # WorkoutTemplate, TemplateExercise
│   ├── BodyEntry.swift              # Body measurements & weight
│   └── PersonalRecord.swift        # PR tracking
├── ViewModels/
│   ├── AppState.swift               # Global @Observable state, workout lifecycle
│   └── ActiveWorkoutViewModel.swift # Active session timers & exercise management
├── Utils/
│   ├── SeedData.swift               # 100+ pre-loaded exercises
│   ├── Extensions.swift             # Date, Double, Color, View helpers
│   └── PlateCalculator.swift        # Plate loading logic
├── Services/
│   ├── NotificationService.swift    # UNUserNotifications (rest timer, reminders)
│   └── ExportService.swift          # CSV export
└── Views/
    ├── Dashboard/DashboardView.swift
    ├── Workout/
    │   ├── ActiveWorkoutView.swift
    │   ├── WorkoutHistoryView.swift
    │   └── WorkoutDetailView.swift
    ├── Exercises/
    │   ├── ExerciseLibraryView.swift
    │   ├── ExerciseDetailView.swift
    │   └── AddExerciseView.swift
    ├── Templates/
    │   ├── TemplatesView.swift
    │   └── TemplateDetailView.swift
    ├── Progress/ProgressView.swift
    ├── Body/BodyTrackingView.swift
    ├── Settings/SettingsView.swift
    └── Components/
        ├── RestTimerView.swift
        └── PlateCalculatorView.swift
```

### Notes

- SwiftData stores data in `~/Library/Application Support/` on device
- All data is local — no network required
- The `@Observable` macro requires iOS 17+ (uses Swift 5.9 Observation framework)
- Charts require iOS 16+ (included here as we target iOS 17+)
