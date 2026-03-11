import SwiftUI

struct PlateCalculatorView: View {
    @Environment(AppState.self) var appState
    @State private var targetWeight: Double = 135

    private var result: PlateCalculator.PlateResult {
        PlateCalculator.calculate(targetWeight: targetWeight, unit: appState.weightUnit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weight Input
                    VStack(spacing: 8) {
                        Text("Target Weight")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button { targetWeight = max(45, targetWeight - 5) } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                            }
                            Text("\(targetWeight.cleanString) \(appState.weightUnit.rawValue)")
                                .font(.largeTitle.monospacedDigit()).bold()
                                .frame(minWidth: 150)
                            Button { targetWeight += 5 } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Slider(value: $targetWeight, in: 45...600, step: 2.5)
                            .tint(.orange)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Quick weights
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common Weights")
                            .font(.subheadline.bold())
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(PlateCalculator.commonWeights(unit: appState.weightUnit), id: \.self) { w in
                                    Button {
                                        targetWeight = w
                                    } label: {
                                        Text("\(w.cleanString)")
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(targetWeight == w ? Color.orange : Color(.systemGray5))
                                            .foregroundStyle(targetWeight == w ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Bar visualization
                    barVisualization

                    // Plate breakdown
                    platesBreakdown
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Bar Visualization

    private var barVisualization: some View {
        let colors: [Color] = [.red, .blue, .yellow, .green, .white, .gray, .orange]
        let plateSizes = [45, 35, 25, 10, 5, 2.5, 1.25]

        return VStack(spacing: 8) {
            Text("Bar Visualization")
                .font(.subheadline.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Left plates (reversed)
                    HStack(spacing: 2) {
                        ForEach(result.plates.reversed().indices, id: \.self) { i in
                            let plate = result.plates.reversed()[i]
                            PlateView(weight: plate, colors: colors, plateSizes: plateSizes)
                        }
                    }

                    // Bar
                    Rectangle()
                        .fill(Color(.systemGray3))
                        .frame(width: 80, height: 18)
                        .overlay(
                            Text("Bar")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        )

                    // Right plates
                    HStack(spacing: 2) {
                        ForEach(result.plates.indices, id: \.self) { i in
                            PlateView(weight: result.plates[i], colors: colors, plateSizes: plateSizes)
                        }
                    }
                }
                .frame(minWidth: 300)
            }
            .padding()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Plates Breakdown

    private var platesBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Per Side")
                    .font(.subheadline.bold())
                Spacer()
                Text("Loaded: \(result.totalWeight.cleanString) \(appState.weightUnit.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if result.plates.isEmpty {
                Text("Bar only (\(appState.weightUnit == .lbs ? "45" : "20") \(appState.weightUnit.rawValue))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let grouped = Dictionary(grouping: result.plates, by: { $0 })
                ForEach(grouped.keys.sorted(by: >), id: \.self) { weight in
                    HStack {
                        Text("× \(grouped[weight]!.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .leading)
                        Text("\(weight.cleanString) \(appState.weightUnit.rawValue)")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("= \((weight * Double(grouped[weight]!.count)).cleanString) \(appState.weightUnit.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                }
            }

            if result.remainder > 0 {
                Text("⚠️ \(result.remainder.cleanString) \(appState.weightUnit.rawValue) can't be loaded with standard plates")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PlateView: View {
    let weight: Double
    let colors: [Color]
    let plateSizes: [Double]

    var plateColor: Color {
        let idx = plateSizes.firstIndex(of: weight) ?? 0
        return colors[min(idx, colors.count - 1)]
    }

    var plateHeight: CGFloat {
        switch weight {
        case 45: return 80
        case 35: return 70
        case 25: return 60
        case 10: return 50
        case 5: return 40
        case 2.5: return 30
        default: return 24
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(plateColor)
            .frame(width: 22, height: plateHeight)
            .overlay(
                Text(weight.cleanString)
                    .font(.system(size: 7))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-90))
            )
    }
}
