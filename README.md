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
