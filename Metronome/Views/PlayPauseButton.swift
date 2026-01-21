import SwiftUI

/// Large circular button to start/stop the metronome.
///
/// Displays:
/// - Play icon (play.fill) when stopped
/// - Pause icon (pause.fill) when playing
///
/// Handles errors from toggle() with console logging for MVP.
struct PlayPauseButton: View {
    @Environment(MetronomeViewModel.self) private var viewModel

    /// Button size
    private let buttonSize: CGFloat = 100

    var body: some View {
        Button {
            do {
                try viewModel.toggle()
            } catch {
                // Log to console for MVP - in production, show user alert
                print("Failed to toggle metronome: \(error)")
            }
        } label: {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 48))
                .foregroundColor(.white)
                .frame(width: buttonSize, height: buttonSize)
                .background(viewModel.isPlaying ? Color.red : Color.blue)
                .clipShape(Circle())
        }
    }
}

#Preview {
    PlayPauseButton()
        .environment(MetronomeViewModel())
}
