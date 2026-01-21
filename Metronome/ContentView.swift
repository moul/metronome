import SwiftUI

/// Main view displaying the metronome interface.
///
/// This is a placeholder view that validates the SwiftUI architecture.
/// It will be replaced with polished components in Plan 02.
struct ContentView: View {
    @Environment(MetronomeViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // BPM Display
            VStack(spacing: 8) {
                Text("\(viewModel.bpm)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("BPM")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            // Beat indicator
            HStack(spacing: 12) {
                ForEach(0..<viewModel.beatsPerBar, id: \.self) { beat in
                    Circle()
                        .fill(beatColor(for: beat))
                        .frame(width: 16, height: 16)
                }
            }

            Spacer()

            // Play/Stop Button
            Button {
                do {
                    try viewModel.toggle()
                } catch {
                    // Handle error - in production, show alert
                    print("Failed to toggle: \(error)")
                }
            } label: {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 100)
                    .background(viewModel.isPlaying ? Color.red : Color.blue)
                    .clipShape(Circle())
            }

            Spacer()
        }
        .padding()
    }

    /// Returns the color for a beat indicator.
    private func beatColor(for beat: Int) -> Color {
        guard viewModel.isPlaying else {
            return .gray.opacity(0.3)
        }

        if beat == viewModel.currentBeat {
            return beat == 0 ? .red : .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
}

#Preview {
    ContentView()
        .environment(MetronomeViewModel())
}
