import SwiftUI

/// Main view composing all metronome UI components.
///
/// Layout (top to bottom):
/// - BeatIndicatorView: Visual beat feedback with pulse animation
/// - BPMControlView: BPM display, slider, and +/- buttons
/// - PlayPauseButton + TapTempoButton: Primary controls
struct ContentView: View {
    @Environment(MetronomeViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Visual beat indicator (primary focus at top)
            BeatIndicatorView()

            Spacer()

            // BPM controls
            BPMControlView()

            Spacer()

            // Bottom controls: Play/Pause and Tap Tempo
            HStack(spacing: 40) {
                PlayPauseButton()
                TapTempoButton()
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(MetronomeViewModel())
}
