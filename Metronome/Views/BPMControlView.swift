import SwiftUI

/// BPM control view with slider and increment/decrement buttons.
///
/// Provides multiple ways to adjust tempo:
/// - Large BPM display showing current value
/// - Slider for coarse adjustments (30-300 BPM range)
/// - +/- buttons for fine adjustments (1 BPM increments)
struct BPMControlView: View {
    @Environment(MetronomeViewModel.self) private var viewModel

    /// BPM range limits
    private let minBPM: Double = 30
    private let maxBPM: Double = 300

    var body: some View {
        VStack(spacing: 16) {
            // Large BPM display
            VStack(spacing: 4) {
                Text("\(viewModel.bpm)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("BPM")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            // Slider for coarse control
            @Bindable var vm = viewModel
            Slider(
                value: Binding(
                    get: { Double(viewModel.bpm) },
                    set: { viewModel.setBPM(Int($0)) }
                ),
                in: minBPM...maxBPM,
                step: 1
            )
            .tint(.blue)
            .padding(.horizontal, 24)

            // +/- buttons for fine control
            HStack(spacing: 40) {
                // Decrement button
                Button {
                    viewModel.decrementBPM()
                } label: {
                    Image(systemName: "minus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }

                // Increment button
                Button {
                    viewModel.incrementBPM()
                } label: {
                    Image(systemName: "plus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
    }
}

#Preview {
    BPMControlView()
        .environment(MetronomeViewModel())
}
