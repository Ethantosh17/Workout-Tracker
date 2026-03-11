import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Query(sort: \WorkoutTemplate.lastUsed, order: .reverse) var templates: [WorkoutTemplate]
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var context

    @State private var showCreateTemplate = false

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                TemplateEditView(template: nil)
            }
        }
    }

    private var templateList: some View {
        List {
            ForEach(templates) { template in
                NavigationLink(destination: TemplateDetailView(template: template)) {
                    TemplateRow(template: template)
                }
            }
            .onDelete { offsets in
                for i in offsets {
                    context.delete(templates[i])
                }
                try? context.save()
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Templates Yet")
                .font(.title2.bold())
            Text("Create templates to quickly start your favorite workouts.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                showCreateTemplate = true
            } label: {
                Label("Create Template", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.orange)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text("\(template.exerciseCount) exercises")
                    Text("•")
                    Text("\(template.totalTargetSets) sets")
                    Text("•")
                    Text("~\(template.estimatedDurationMinutes) min")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !template.notes.isEmpty {
                    Text(template.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let lastUsed = template.lastUsed {
                VStack(alignment: .trailing) {
                    Text("\(template.timesUsed)×")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Text(lastUsed.relativeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
