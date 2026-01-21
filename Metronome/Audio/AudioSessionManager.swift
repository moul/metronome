import Foundation
import AVFoundation

/// Custom notification for audio interruption ended events.
extension Notification.Name {
    /// Posted when an audio interruption ends.
    /// The userInfo dictionary contains `shouldResume` (Bool) indicating if playback should resume.
    static let audioInterruptionEnded = Notification.Name("audioInterruptionEnded")
}

/// Manages AVAudioSession configuration for background audio playback.
///
/// AudioSessionManager configures the audio session for the `.playback` category,
/// which enables background audio. It also observes interruption notifications
/// (phone calls, alarms, etc.) and posts a custom notification when interruptions end.
@MainActor
public final class AudioSessionManager {
    /// Whether the audio session has been configured.
    public private(set) var isConfigured: Bool = false

    /// The shared AVAudioSession instance.
    private let session: AVAudioSession

    /// Observer token for interruption notifications.
    private var interruptionObserver: NSObjectProtocol?

    // MARK: - Initialization

    public init() {
        self.session = AVAudioSession.sharedInstance()
        setupInterruptionObserver()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Configuration

    /// Configure the audio session for playback.
    ///
    /// Sets the category to `.playback` which enables background audio playback.
    /// This must be called before starting audio playback.
    ///
    /// - Throws: Errors from AVAudioSession configuration
    public func configureForPlayback() throws {
        guard !isConfigured else { return }

        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)

        isConfigured = true
    }

    /// Deactivate the audio session.
    ///
    /// Call this when the app is done with audio playback to allow other apps
    /// to use audio.
    public func deactivate() {
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            isConfigured = false
        } catch {
            // Deactivation can fail if audio is still playing elsewhere
            // This is not a critical error
        }
    }

    // MARK: - Interruption Handling

    private func setupInterruptionObserver() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption started (phone call, alarm, etc.)
            // The system automatically pauses audio
            break

        case .ended:
            // Interruption ended
            var shouldResume = false

            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                shouldResume = options.contains(.shouldResume)
            }

            // Post notification for ViewModel to observe
            NotificationCenter.default.post(
                name: .audioInterruptionEnded,
                object: self,
                userInfo: ["shouldResume": shouldResume]
            )

        @unknown default:
            break
        }
    }
}
