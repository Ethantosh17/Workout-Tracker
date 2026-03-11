import SwiftUI

struct RestTimerOverlay: View {
    @Bindable var vm: ActiveWorkoutViewModel
    let defaultRestTime: Int

    var body: some View {
        if vm.restTimerActive {
            VStack(spacing: 16) {
                HStack {
                    Text("Rest Timer")
                        .font(.headline)
                    Spacer()
                    Button {
                        vm.skipRestTimer()
                        NotificationService.shared.cancelRestTimerNotification()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: vm.restProgress)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: vm.restProgress)
                    Text(vm.restFormatted)
                        .font(.title2.monospacedDigit()).bold()
                }

                HStack(spacing: 12) {
                    ForEach([-15, +15, +30], id: \.self) { delta in
                        Button {
                            vm.addRestTime(delta)
                        } label: {
                            Text(delta > 0 ? "+\(delta)s" : "\(delta)s")
                                .font(.caption).bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    Button {
                        vm.skipRestTimer()
                        NotificationService.shared.cancelRestTimerNotification()
                    } label: {
                        Text("Skip")
                            .font(.caption).bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
