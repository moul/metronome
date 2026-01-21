import SwiftUI

/// Main entry point for the Metronome app.
@main
struct MetronomeApp: App {
    /// The shared ViewModel instance injected into the environment.
    @State private var viewModel = MetronomeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
