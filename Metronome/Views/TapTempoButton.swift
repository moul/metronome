import SwiftUI

/// Tap tempo button for detecting tempo from repeated taps.
///
/// Users tap this button rhythmically to set the BPM.
/// Displays:
/// - "TAP" label
/// - Current tap count from viewModel.tapCount
struct TapTempoButton: View {
    @Environment(MetronomeViewModel.self) private var viewModel

    var body: some View {
        Button {
            viewModel.recordTap()
        } label: {
            VStack(spacing: 4) {
                Text("TAP")
                    .font(.title2)
                    .fontWeight(.bold)

                // Show tap count (0 means no taps yet)
                Text("\(viewModel.tapCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(Color.orange)
            .clipShape(Circle())
        }
    }
}

#Preview {
    TapTempoButton()
        .environment(MetronomeViewModel())
}
