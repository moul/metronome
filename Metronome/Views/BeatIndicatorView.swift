import SwiftUI

/// Visual beat indicator that pulses in sync with the metronome engine.
///
/// This view displays:
/// - Current beat number (1-based for user display)
/// - Pulsing animation triggered by beat changes
/// - Distinct color for accent beats (beat 1/downbeat)
///
/// CRITICAL: Visual is driven by engine state (viewModel.currentBeat), NOT a separate timer.
/// This ensures perfect synchronization between audio and visual.
struct BeatIndicatorView: View {
    @Environment(MetronomeViewModel.self) private var viewModel

    /// Animation state for pulse effect
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0

    /// Size of the main indicator circle
    private let indicatorSize: CGFloat = 160

    var body: some View {
        ZStack {
            // Pulse ring (expands outward on beat)
            Circle()
                .stroke(accentColor, lineWidth: 4)
                .frame(width: indicatorSize, height: indicatorSize)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)

            // Main indicator circle
            Circle()
                .fill(viewModel.isPlaying ? accentColor : Color.gray.opacity(0.3))
                .frame(width: indicatorSize, height: indicatorSize)

            // Beat number display (1-based for users)
            Text("\(displayBeat)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .onChange(of: viewModel.currentBeat) { _, _ in
            triggerPulse()
        }
    }

    /// The beat number to display (1-based, since engine uses 0-based)
    private var displayBeat: Int {
        viewModel.currentBeat + 1
    }

    /// Color based on whether current beat is an accent (downbeat)
    private var accentColor: Color {
        viewModel.isAccent ? .red : .blue
    }

    /// Triggers the pulse animation when a beat occurs
    private func triggerPulse() {
        // Reset state for new pulse
        pulseScale = 1.0
        pulseOpacity = 0.8

        // Animate outward expansion and fade
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.4
            pulseOpacity = 0.0
        }
    }
}

#Preview {
    BeatIndicatorView()
        .environment(MetronomeViewModel())
}
