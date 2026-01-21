/// MetronomeCore - Platform-independent timing and tempo logic
///
/// This module provides core metronome functionality without any UI or audio dependencies.
/// It includes BPM validation, tap tempo calculation, and timing utilities.

/// The current version of MetronomeCore
public let version = "0.1.0"

// Re-export public types
@_exported import struct Foundation.Date
@_exported import struct Foundation.TimeInterval
